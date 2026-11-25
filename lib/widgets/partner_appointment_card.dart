import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class PartnerAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final bool isDoctorPartner;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onStartVideoCall;
  final ValueChanged<String>? onUpdateStatus;
  final bool isVideo;
  final bool isWindowOpen;
  final String windowStartText;

  const PartnerAppointmentCard({
    super.key,
    required this.appt,
    required this.isDoctorPartner,
    required this.onTap,
    this.onCall,
    this.onStartVideoCall,
    this.onUpdateStatus,
    this.isVideo = false,
    this.isWindowOpen = false,
    this.windowStartText = '',
  });

  static Color getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase().trim()) {
      case 'confirmed':
        return const Color(0xFF0D9488);
      case 'upcoming':
      case 'pending':
      case '':
        return const Color(0xFFD97706);
      case 'completed':
        return const Color(0xFF15803D);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return Colors.blueGrey;
    }
  }

  static IconData getTypeIcon(String? type) {
    switch ((type ?? '').toLowerCase().trim()) {
      case 'opd':
        return Icons.local_hospital_rounded;
      case 'pathology':
        return Icons.biotech_rounded;
      case 'doctor':
        return Icons.person_rounded;
      case 'others':
        return Icons.accessibility_new_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  static String formatTime12h(String? time24h) {
    if (time24h == null || time24h == 'N/A' || time24h.trim().isEmpty) {
      return 'N/A';
    }
    try {
      final raw = time24h.trim();
      final upper = raw.toUpperCase();
      if (upper.endsWith('AM') || upper.endsWith('PM')) return raw;
      final parts = raw.split(':');
      if (parts.length < 2) return raw;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return time24h;
    }
  }

  static String resolveServiceName(Map<String, dynamic> appt) {
    final clinicType = (appt['clinic_type'] ?? '').toString().toLowerCase().trim();
    final isPathology = clinicType == 'pathology';
    final resService = appt['resolved_service_name']?.toString().trim();
    final resDoc = appt['resolved_doctor_name']?.toString().trim();
    if (resService != null && resService.isNotEmpty && resService != 'N/A') {
      return resService;
    }
    if (resDoc != null && resDoc.isNotEmpty && resDoc != 'N/A') {
      return resDoc;
    }
    if (isPathology) {
      return (appt['test']?['test_name'] ??
              appt['test_name'] ??
              appt['clinic_name'] ??
              'Diagnostic Test')
          .toString();
    }
    return (appt['doctor_contact']?['partner_doctor_name'] ??
            appt['clinic_name'] ??
            appt['doctor']?['doctor_name'] ??
            appt['doctor_name'] ??
            'Specialist Consultation')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final patientName =
        (appt['user_name'] ?? appt['user']?['user_name'] ?? 'N/A').toString();
    final date = (appt['booking_date'] ?? 'N/A').toString();
    final time = formatTime12h(appt['booking_time']?.toString());
    final clinicType = (appt['clinic_type'] ?? 'Appointment').toString();
    final visitMode = (appt['visit_mode'] ?? '').toString();
    final rawStatus = (appt['status'] ?? 'Upcoming').toString().trim();
    final normStatus = rawStatus.toLowerCase();
    final statusText = rawStatus.isEmpty ? 'Upcoming' : rawStatus;
    final statusColor = getStatusColor(statusText);
    final isPathology = clinicType.toLowerCase() == 'pathology';
    final serviceName = resolveServiceName(appt);
    final serial = appt['enquiry_serial']?.toString();

    final bool isUpcomingGroup = normStatus == 'upcoming' ||
        normStatus == 'pending' ||
        normStatus == 'confirmed' ||
        normStatus.isEmpty;

    final String subtitleText = (isDoctorPartner && !isPathology)
        ? (visitMode.isNotEmpty ? '${visitMode.toUpperCase()} Visit' : 'Consultation')
        : serviceName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Highlighted Header (Date & Time) at Top
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: statusColor.withValues(alpha: 0.07),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded, size: 13, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        time,
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Compact Main Summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getTypeIcon(clinicType),
                          color: statusColor,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  clinicType.toUpperCase(),
                                  style: GoogleFonts.manrope(
                                    color: statusColor.withValues(alpha: 0.85),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                if (serial != null && serial.isNotEmpty && serial != 'N/A') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'SL: $serial',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                _buildStatusBadge(statusText, statusColor),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              patientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Details',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 15, color: statusColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Compact Single-Row Action Bar (only for active upcoming/confirmed)
                if (isUpcomingGroup && onUpdateStatus != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 11),
                    child: Row(
                      children: [
                        if (isVideo && onStartVideoCall != null) ...[
                          Expanded(
                            flex: 5,
                            child: isWindowOpen
                                ? InkWell(
                                    onTap: onStartVideoCall,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7.5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.videocam_rounded, color: Colors.white, size: 15),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Join Call',
                                              style: GoogleFonts.manrope(
                                                color: Colors.white,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.videocam_outlined, color: Colors.blueGrey[500], size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            windowStartText,
                                            style: GoogleFonts.manrope(
                                              color: Colors.blueGrey[700],
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          flex: 3,
                          child: _compactActionButton(
                            normStatus == 'confirmed' ? Icons.task_alt_rounded : Icons.check_circle_outline,
                            normStatus == 'confirmed' ? 'Complete' : 'Confirm',
                            normStatus == 'confirmed' ? const Color(0xFF15803D) : AppColors.teal,
                            () => onUpdateStatus!(normStatus == 'confirmed' ? 'Completed' : 'Confirmed'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: _compactActionButton(
                            Icons.cancel_outlined,
                            'Cancel',
                            const Color(0xFFDC2626),
                            () => onUpdateStatus!('Cancelled'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildStatusBadge(String statusText, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: GoogleFonts.manrope(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static Widget _compactActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _modernActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showDetailsModal({
    required BuildContext context,
    required Map<String, dynamic> appt,
    required bool isDoctorPartner,
    VoidCallback? onCall,
    VoidCallback? onStartVideoCall,
    ValueChanged<String>? onUpdateStatus,
    VoidCallback? onOpenFullDetails,
    bool isVideo = false,
    bool isWindowOpen = false,
    String windowStartText = '',
  }) {
    final patientName =
        (appt['user_name'] ?? appt['user']?['user_name'] ?? 'N/A').toString();
    final patientMobile =
        (appt['user_mobile'] ?? appt['user']?['user_mobile'] ?? 'N/A').toString();
    final patientEmail =
        (appt['user_email'] ?? appt['user']?['user_email'] ?? '').toString().trim();
    final date = (appt['booking_date'] ?? 'N/A').toString();
    final time = formatTime12h(appt['booking_time']?.toString());
    final visitMode = (appt['visit_mode'] ?? '').toString();
    final clinicType = (appt['clinic_type'] ?? 'Appointment').toString();
    final serial = (appt['enquiry_serial'] ?? '').toString().trim();
    final rawStatus = (appt['status'] ?? 'Upcoming').toString().trim();
    final normStatus = rawStatus.toLowerCase();
    final statusText = rawStatus.isEmpty ? 'Upcoming' : rawStatus;
    final statusColor = getStatusColor(statusText);
    final isPathology = clinicType.toLowerCase() == 'pathology';
    final serviceName = resolveServiceName(appt);
    final paymentAmount = (appt['payment_amount'] ?? '').toString().trim();
    final paymentStatus = (appt['payment_status'] ?? '').toString().trim();
    final userInquiry = (appt['user_inquiry'] ?? '').toString().trim();
    final slotTimingInfo = _getSlotTimingInfo(appt);
    final subSlotDetails = _getSubSlotDetails(appt);

    final bool isUpcomingGroup = normStatus == 'upcoming' ||
        normStatus == 'pending' ||
        normStatus == 'confirmed' ||
        normStatus.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(modalCtx).viewPadding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Modal Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        getTypeIcon(clinicType),
                        color: statusColor,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                clinicType.toUpperCase(),
                                style: GoogleFonts.manrope(
                                  color: statusColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              _buildStatusBadge(statusText, statusColor),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patientName,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (!(isDoctorPartner && !isPathology))
                            Text(
                              serviceName,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1565C0),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // All Details Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      if (serial.isNotEmpty && serial != 'N/A') ...[
                        _detailRow(Icons.confirmation_number_outlined, 'Serial / Token', 'SL: $serial', isHighlighted: true),
                        const SizedBox(height: 6),
                      ],
                      _detailRow(Icons.calendar_today_outlined, 'Date', date, isHighlighted: true),
                      const SizedBox(height: 6),
                      _detailRow(Icons.access_time_rounded, 'Booking Time', time, isHighlighted: true),
                      if (slotTimingInfo != null && slotTimingInfo.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.schedule_rounded, 'Slot Timing', slotTimingInfo, isHighlighted: true),
                      ],
                      if (subSlotDetails != null && subSlotDetails.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.timer_outlined, 'Slot Details', subSlotDetails, isHighlighted: true),
                      ],
                      if (visitMode.isNotEmpty && visitMode != 'N/A') ...[
                        const SizedBox(height: 6),
                        _detailRow(
                          isVideo ? Icons.videocam_outlined : Icons.apartment_rounded,
                          'Visit Mode',
                          isVideo ? 'Online Video Consultation' : '${visitMode[0].toUpperCase()}${visitMode.substring(1)} Visit',
                        ),
                      ],
                      if (patientMobile.isNotEmpty && patientMobile != 'N/A') ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.phone_outlined, 'Mobile', patientMobile),
                      ],
                      if (patientEmail.isNotEmpty && patientEmail != 'N/A') ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.email_outlined, 'Email', patientEmail),
                      ],
                      if (!(isDoctorPartner && !isPathology)) ...[
                        const SizedBox(height: 6),
                        _detailRow(
                          isPathology ? Icons.biotech_outlined : Icons.medical_services_outlined,
                          isPathology ? 'Test' : 'Doctor / Clinic',
                          serviceName,
                        ),
                      ],
                      if (paymentAmount.isNotEmpty && paymentAmount != 'null') ...[
                        const SizedBox(height: 6),
                        _detailRow(
                          Icons.payments_outlined,
                          'Fee',
                          '₹$paymentAmount${paymentStatus.isNotEmpty ? ' (${paymentStatus.toUpperCase()})' : ''}',
                          isHighlighted: true,
                        ),
                      ],
                      if (userInquiry.isNotEmpty && userInquiry != 'N/A') ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.notes_rounded, 'Notes', userInquiry),
                      ],
                    ],
                  ),
                ),

                // Call Patient Button
                if (patientMobile.isNotEmpty && patientMobile != 'N/A' && onCall != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        onCall();
                      },
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                      label: Text(
                        'Call Patient ($patientMobile)',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],

                // Video Consultation Button
                if (isUpcomingGroup && isVideo && onStartVideoCall != null) ...[
                  const SizedBox(height: 12),
                  isWindowOpen
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(modalCtx);
                              onStartVideoCall();
                            },
                            icon: const Icon(Icons.videocam_rounded, size: 20),
                            label: Text(
                              'Start Video Consultation',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_outlined, color: Colors.blueGrey[400], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Video Call: $windowStartText',
                                style: GoogleFonts.manrope(
                                  color: Colors.blueGrey[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ],

                // Confirm / Complete / Cancel Buttons
                if (isUpcomingGroup && onUpdateStatus != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _modernActionButton(
                          normStatus == 'confirmed' ? Icons.task_alt_rounded : Icons.check_circle_outline,
                          normStatus == 'confirmed' ? 'Mark Complete' : 'Confirm',
                          normStatus == 'confirmed' ? const Color(0xFF15803D) : AppColors.teal,
                          () {
                            Navigator.pop(modalCtx);
                            onUpdateStatus(normStatus == 'confirmed' ? 'Completed' : 'Confirmed');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _modernActionButton(
                          Icons.cancel_outlined,
                          'Cancel',
                          const Color(0xFFDC2626),
                          () {
                            Navigator.pop(modalCtx);
                            onUpdateStatus('Cancelled');
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                // Optional Full Page Link (Prescriptions / Notes / Detailed View)
                if (onOpenFullDetails != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        onOpenFullDetails();
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: Text(
                        'Open Full Appointment Page',
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _detailRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    final Color valueColor = isHighlighted ? const Color(0xFF1565C0) : const Color(0xFF455A64);
    final Color labelColor = isHighlighted ? const Color(0xFF1565C0).withValues(alpha: 0.78) : Colors.blueGrey[400]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(icon, size: 14, color: isHighlighted ? const Color(0xFF1565C0) : Colors.blueGrey[300]),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: labelColor,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int? _parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final raw = timeStr.trim();
      final parts = raw.split(' ');
      final hms = parts[0].split(':');
      int h = int.parse(hms[0]);
      int m = hms.length > 1 ? int.parse(hms[1]) : 0;
      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && h < 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
      }
      return h * 60 + m;
    } catch (_) {
      return null;
    }
  }

  static String? _getSlotTimingInfo(Map<String, dynamic> appt) {
    // Check direct slot fields if present
    final directSlot = (appt['slot_timing'] ?? appt['slot_details'] ?? appt['slot_name'] ?? '')
        .toString()
        .trim();
    if (directSlot.isNotEmpty && directSlot != 'null' && directSlot != 'N/A') {
      return directSlot;
    }

    final bookingDate = appt['booking_date']?.toString().trim();
    final bookingTime = appt['booking_time']?.toString().trim();
    final int? bookingMins = _parseTimeToMinutes(bookingTime);

    final rawSchedule = appt['doctor_contact']?['visit_day_time'] ??
        appt['doctor']?['visit_day_time'] ??
        appt['test']?['test_day_time'];

    List<dynamic> scheduleList = [];
    if (rawSchedule is List) {
      scheduleList = rawSchedule;
    } else if (rawSchedule is String && rawSchedule.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSchedule);
        if (decoded is List) scheduleList = decoded;
      } catch (_) {}
    }

    if (scheduleList.isEmpty) return null;

    // 1. Date-based slot matching (Doctor / Others)
    if (bookingDate != null && bookingDate.isNotEmpty) {
      for (final entry in scheduleList) {
        if (entry is! Map) continue;
        final schedType = (entry['schedule_type'] ?? entry['type'] ?? '').toString().toLowerCase();
        final entryDate = entry['date']?.toString().trim();
        if (schedType == 'date' && entryDate == bookingDate) {
          final slots = entry['slots'];
          if (slots is List && slots.isNotEmpty) {
            if (bookingMins != null) {
              for (final s in slots) {
                if (s is! Map) continue;
                final sStart = s['start_time']?.toString();
                final sEnd = s['end_time']?.toString();
                final int startMin = _parseTimeToMinutes(sStart) ?? 0;
                final int endMin = _parseTimeToMinutes(sEnd) ?? 1439;
                if (bookingMins >= startMin && bookingMins <= endMin) {
                  final sId = (s['id'] ?? '').toString();
                  final sName = (s['name'] ??
                          (sId.isNotEmpty ? '${sId[0].toUpperCase()}${sId.substring(1)}' : 'Slot'))
                      .toString();
                  if (sStart != null && sEnd != null) {
                    return '$sName (${formatTime12h(sStart)} - ${formatTime12h(sEnd)})';
                  }
                  return '$sName (${formatTime12h(bookingTime)})';
                }
              }
            }
            // Fallback: list all slots configured for that date
            final allLabels = slots.whereType<Map>().map((s) {
              final sId = (s['id'] ?? '').toString();
              final sName = (s['name'] ??
                      (sId.isNotEmpty ? '${sId[0].toUpperCase()}${sId.substring(1)}' : 'Slot'))
                  .toString();
              final sStart = s['start_time']?.toString();
              final sEnd = s['end_time']?.toString();
              if (sStart != null && sEnd != null) {
                return '$sName (${formatTime12h(sStart)} - ${formatTime12h(sEnd)})';
              }
              return sName;
            }).join(', ');
            if (allLabels.isNotEmpty) return allLabels;
          }
        }
      }

      // 2. Weekday-based schedule matching (OPD / Pathology)
      try {
        final parsedDate = DateTime.parse(bookingDate);
        const weekdays = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ];
        final targetDay = weekdays[parsedDate.weekday - 1];
        for (final entry in scheduleList) {
          if (entry is! Map) continue;
          final dayStr = (entry['doctor_visit_day'] ?? entry['day'] ?? '').toString().toLowerCase().trim();
          if (dayStr.isNotEmpty && (dayStr == targetDay || targetDay.startsWith(dayStr) || dayStr.startsWith(targetDay.substring(0, 3)))) {
            final start = (entry['doctor_visit_start_time'] ?? entry['start_time'] ?? '').toString().trim();
            final end = (entry['doctor_visit_end_time'] ?? entry['end_time'] ?? '').toString().trim();
            final dayLabel = (entry['doctor_visit_day'] ?? entry['day'] ?? '').toString().trim();
            if (start.isNotEmpty && end.isNotEmpty) {
              return '$dayLabel (${formatTime12h(start)} - ${formatTime12h(end)})';
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  static String? _getSubSlotDetails(Map<String, dynamic> appt) {
    final bookingDate = appt['booking_date']?.toString().trim();
    final bookingTime = appt['booking_time']?.toString().trim();
    final int? bookingMins = _parseTimeToMinutes(bookingTime);
    if (bookingMins == null || bookingDate == null || bookingDate.isEmpty) return null;

    final rawSchedule = appt['doctor_contact']?['visit_day_time'] ??
        appt['doctor']?['visit_day_time'] ??
        appt['test']?['test_day_time'];

    List<dynamic> scheduleList = [];
    if (rawSchedule is List) {
      scheduleList = rawSchedule;
    } else if (rawSchedule is String && rawSchedule.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSchedule);
        if (decoded is List) scheduleList = decoded;
      } catch (_) {}
    }

    for (final entry in scheduleList) {
      if (entry is! Map) continue;
      final schedType = (entry['schedule_type'] ?? entry['type'] ?? '').toString().toLowerCase();
      final entryDate = entry['date']?.toString().trim();
      if (schedType == 'date' && entryDate == bookingDate) {
        final slots = entry['slots'];
        if (slots is List) {
          for (final s in slots) {
            if (s is! Map) continue;
            final sStart = s['start_time']?.toString();
            final sEnd = s['end_time']?.toString();
            if (sStart == null) continue;
            final int? startMin = _parseTimeToMinutes(sStart);
            if (startMin == null) continue;
            int endMin = (sEnd != null ? _parseTimeToMinutes(sEnd) : null) ?? (startMin + 60);
            if (endMin <= startMin) endMin = startMin + 60;

            if (bookingMins >= startMin && bookingMins < endMin) {
              final int slotIndex = ((bookingMins - startMin) ~/ 10) + 1;
              final int subStart = startMin + (slotIndex - 1) * 10;
              final int subEnd = (subStart + 10 <= endMin) ? (subStart + 10) : endMin;

              String fmtMin(int mins) {
                final h24 = mins ~/ 60;
                final m = mins % 60;
                final period = h24 >= 12 ? 'PM' : 'AM';
                final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
                return '$h12:${m.toString().padLeft(2, '0')} $period';
              }

              return 'Slot $slotIndex (${fmtMin(subStart)} - ${fmtMin(subEnd)})';
            }
          }
        }
      }
    }
    return null;
  }
}
