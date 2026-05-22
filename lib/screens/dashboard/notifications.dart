import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'appointments/details.dart';

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const NotificationsScreen({super.key, required this.partnerData});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _readKey = 'partner_read_booking_ids';
  bool _isLoading = true;
  List<dynamic> _appointments = [];
  Set<String> _readBookingIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadStateAndFetch();
  }

  Future<void> _loadReadStateAndFetch() async {
    await _loadReadBookingIds();
    await _fetchNotifications();
  }

  Future<void> _loadReadBookingIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_readKey) ?? [];
      if (mounted) {
        setState(() {
          _readBookingIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveReadBookingIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readKey, _readBookingIds.toList());
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch all appointments (no status filter to get all bookings)
      final response = await ApiService.getAppointments(token: token);
      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> fetched = response['appointments'] ?? [];
        
        // Sort by id or created_at descending if available
        fetched.sort((a, b) {
          final aId = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return bId.compareTo(aId);
        });

        setState(() {
          _appointments = fetched;
        });
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? 'Failed to load booking notifications.',
        );
      }
    } catch (_) {
      if (mounted) {
        CustomAlerts.showError(
          context,
          'An unexpected error occurred while fetching notifications.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    if (!_readBookingIds.contains(id)) {
      setState(() {
        _readBookingIds.add(id);
      });
      await _saveReadBookingIds();
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadIds = _appointments
        .map((a) => a['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty && !_readBookingIds.contains(id))
        .toList();

    if (unreadIds.isEmpty) return;

    setState(() {
      _readBookingIds.addAll(unreadIds);
    });
    await _saveReadBookingIds();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All notifications marked as read',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.teal,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  DateTime? _parseDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'N/A') return null;
    
    final cleanDate = dateStr.trim();
    final cleanTime = (timeStr != null && timeStr.isNotEmpty && timeStr != 'N/A') ? timeStr.trim() : '00:00:00';
    
    final yyyymmddReg = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    final ddmmyyyyReg = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    
    String finalIsoStr = '';
    if (yyyymmddReg.hasMatch(cleanDate)) {
      finalIsoStr = '${cleanDate}T$cleanTime';
    } else if (ddmmyyyyReg.hasMatch(cleanDate)) {
      final parts = cleanDate.split('-');
      if (parts.length == 3) {
        finalIsoStr = '${parts[2]}-${parts[1]}-${parts[0]}T$cleanTime';
      }
    } else {
      try {
        return DateTime.tryParse('$cleanDate $cleanTime');
      } catch (_) {}
    }
    
    if (finalIsoStr.isNotEmpty) {
      try {
        return DateTime.tryParse(finalIsoStr);
      } catch (_) {}
    }
    
    return null;
  }

  String _getRelativeTime(Map<String, dynamic> appt) {
    // Try created_at
    final createdAt = appt['created_at'];
    if (createdAt != null && createdAt.toString().isNotEmpty) {
      final parsed = DateTime.tryParse(createdAt.toString());
      if (parsed != null) {
        return _formatDifference(parsed.toLocal());
      }
    }

    // Fallback to booking_date & booking_time
    final bookingDate = appt['booking_date'];
    final bookingTime = appt['booking_time'];
    final parsedBooking = _parseDateTime(bookingDate?.toString(), bookingTime?.toString());
    if (parsedBooking != null) {
      return _formatDifference(parsedBooking);
    }
    
    if (bookingDate != null && bookingDate.toString().isNotEmpty) {
      return bookingDate.toString();
    }
    
    return '';
  }

  String _formatDifference(DateTime target) {
    final now = DateTime.now();
    final difference = now.difference(target);

    if (difference.isNegative) {
      final absDiff = difference.abs();
      if (absDiff.inMinutes < 60) {
        final mins = absDiff.inMinutes;
        return 'In $mins ${mins == 1 ? 'min' : 'mins'}';
      } else if (absDiff.inHours < 24) {
        final hours = absDiff.inHours;
        return 'In $hours ${hours == 1 ? 'hour' : 'hours'}';
      } else if (absDiff.inDays == 1) {
        return 'Tomorrow';
      } else if (absDiff.inDays < 7) {
        return 'In ${absDiff.inDays} days';
      } else {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${target.day} ${months[target.month - 1]} ${target.year}';
      }
    } else {
      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${target.day} ${months[target.month - 1]} ${target.year}';
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
    final id = appt['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      await _markAsRead(id);
    }
    
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(
          appointment: appt,
          partnerData: widget.partnerData,
          onStatusUpdated: _fetchNotifications,
        ),
      ),
    );
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _appointments
        .where((a) => !_readBookingIds.contains(a['id']?.toString() ?? ''))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.done_all_rounded, color: AppColors.teal, size: 22),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: AppColors.teal,
              child: _appointments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appt = _appointments[index] as Map<String, dynamic>;
                        final id = appt['id']?.toString() ?? '';
                        final isUnread = !_readBookingIds.contains(id);

                        return FadeInUp(
                          duration: const Duration(milliseconds: 250),
                          child: _buildNotificationCard(appt, isUnread),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.navy,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications Yet',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'When patients book appointments or tests with you, those alerts will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> appt, bool isUnread) {
    final patientName = appt['user_name'] ?? appt['user']?['user_name'] ?? 'N/A';
    final date = appt['booking_date'] ?? 'N/A';
    final time = appt['booking_time'] ?? 'N/A';
    final clinicType = appt['clinic_type'] ?? 'N/A';
    final status = appt['status'] ?? 'Upcoming';
    final relativeTime = _getRelativeTime(appt);

    final isPathology = clinicType.toLowerCase() == 'pathology';
    final serviceName = isPathology
        ? (appt['test']?['test_name'] ?? 'N/A')
        : (appt['doctor']?['doctor_name'] ?? 'N/A');

    // Color definitions based on status
    final Color statusColor;
    final Color statusBg;
    if (status == 'Completed') {
      statusColor = AppColors.teal;
      statusBg = AppColors.teal.withValues(alpha: 0.08);
    } else if (status == 'Cancelled') {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFEF4444).withValues(alpha: 0.08);
    } else {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFD97706).withValues(alpha: 0.08);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF3FAF9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? AppColors.teal.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
          width: isUnread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 8,
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Highlight indicator bar on left for unread items
                Container(
                  width: 4.5,
                  decoration: BoxDecoration(
                    color: isUnread ? AppColors.teal : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row (Service Category and Relative Time)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isPathology ? Colors.purpleAccent : AppColors.teal).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPathology ? Icons.science_rounded : Icons.medical_information_rounded,
                                    size: 11,
                                    color: isPathology ? Colors.purple : AppColors.teal,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPathology ? 'TEST BOOKING' : 'DOCTOR APPOINTMENT',
                                    style: GoogleFonts.manrope(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isPathology ? Colors.purple : AppColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
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
                                if (isUnread) ...[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  relativeTime,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isUnread ? AppColors.teal : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Notification Message Content
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.navy,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: patientName,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(text: ' has booked a new '),
                              TextSpan(
                                text: isPathology ? 'test' : 'appointment',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: ' for '),
                              TextSpan(
                                text: serviceName,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),

                        // Footer row (Scheduled date/time & Status badge)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '$date @ ${_formatTime12h(time)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
