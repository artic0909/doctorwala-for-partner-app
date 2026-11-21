import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'adddoctor.dart';
import '../../widgets/partner_skeleton_loader.dart';

class _DoctorTheme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Turquoise/Teal
  static const Color accentLight = Color(0xFFF0FDFA); // Soft Mint/Turquoise Light
  static const Color bgTint = Color(0xFFF8FAFC); // Slate background
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium slate
}

class ShowDoctorsScreen extends StatefulWidget {
  const ShowDoctorsScreen({super.key});

  @override
  State<ShowDoctorsScreen> createState() => _ShowDoctorsScreenState();
}

class _ShowDoctorsScreenState extends State<ShowDoctorsScreen> {
  bool _isFetching = true;
  bool _isLoading = false;
  List<dynamic> _doctors = [];
  List<dynamic> _filteredDoctors = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
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
        _filteredDoctors = _doctors;
      } else {
        _filteredDoctors =
            _doctors.where((doc) {
              final name = (doc['doctor_name'] ?? '').toString().toLowerCase();
              final spec =
                  (doc['doctor_specialist'] ?? '').toString().toLowerCase();
              final desig =
                  (doc['doctor_designation'] ?? '').toString().toLowerCase();
              return name.contains(query) ||
                  spec.contains(query) ||
                  desig.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _fetchDoctors() async {
    if (!mounted) return;
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
          _filteredDoctors = _doctors;
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
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
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
                color: _DoctorTheme.primary,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this doctor from your seating?',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w500,
                color: _DoctorTheme.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: _DoctorTheme.textSecondary,
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
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
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  void _navigateToAddDoctor({Map<String, dynamic>? doctorToEdit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDoctorScreen(doctorToEdit: doctorToEdit),
      ),
    );
    if (result == true) {
      _fetchDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DoctorTheme.bgTint,
      body: Stack(
        children: [
          Column(
            children: [
              // Custom Header Bar with Search & Add button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blueGrey.withAlpha(20),
                      width: 1.0,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                              'Doctors List',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _DoctorTheme.primary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Listed: ${_doctors.length}',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _DoctorTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // Add Doctors Button
                        SizedBox(
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToAddDoctor(),
                            icon: const Icon(
                              Icons.person_add_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Add Doctor',
                              style: GoogleFonts.manrope(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _DoctorTheme.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _DoctorTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          hintText: 'Search by doctor name or specialty...',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _DoctorTheme.accent,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Listings List
              Expanded(
                child: _isFetching
                    ? const PartnerDoctorsSkeleton()
                    : RefreshIndicator(
                          onRefresh: _fetchDoctors,
                          color: _DoctorTheme.accent,
                          child:
                              _filteredDoctors.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                    padding: EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      top: 14,
                                      bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
                                    ),
                                    itemCount: _filteredDoctors.length,
                                    itemBuilder: (context, idx) {
                                      final doc =
                                          _filteredDoctors[idx]
                                              as Map<String, dynamic>;
                                      return FadeInUp(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: _buildDoctorCard(doc),
                                      );
                                    },
                                  ),
                        ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_DoctorTheme.accent),
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
              decoration: const BoxDecoration(
                color: _DoctorTheme.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_information_rounded,
                color: _DoctorTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty ? 'No Doctors Registered' : 'No Results Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _DoctorTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Tap "+ Add Doctor" at the top to configure your clinic practitioners.'
                  : 'We couldn\'t find any matches for "$query". Try typing a different name.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _DoctorTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    final id = doc['id']?.toString() ?? '';
    final name = doc['doctor_name'] ?? 'N/A';
    final spec = doc['doctor_specialist'] ?? 'N/A';
    final desig = doc['doctor_designation'] ?? 'N/A';
    final fees = doc['doctor_fees']?.toString() ?? '0';
    final more = doc['doctor_more']?.toString() ?? '';

    // Decode visit days
    List<dynamic> rawDaysList = [];
    final visitData = doc['visit_day_time'];
    if (visitData != null) {
      if (visitData is List) {
        rawDaysList = visitData;
      } else if (visitData is String) {
        try {
          rawDaysList = jsonDecode(visitData);
        } catch (_) {}
      }
    }

    // Filter active schedules (ignore days without timings)
    final List<Map<String, String>> activeSchedules = [];
    for (var sched in rawDaysList) {
      if (sched is! Map) continue;
      final dayName = sched['day']?.toString() ?? '';
      final start = sched['start_time']?.toString() ?? '';
      final end = sched['end_time']?.toString() ?? '';

      final startDisplay = _formatDBTime(start);
      final endDisplay = _formatDBTime(end);

      String displayTime = '';
      if (startDisplay.isEmpty && endDisplay.isEmpty) {
        displayTime = '';
      } else if (endDisplay.isEmpty) {
        displayTime = '$startDisplay onwards';
      } else if (startDisplay.isEmpty) {
        displayTime = 'Till $endDisplay';
      } else {
        displayTime = '$startDisplay - $endDisplay';
      }

      if (displayTime.isNotEmpty) {
        String shortDay = dayName;
        if (dayName.length > 3 && dayName.toLowerCase() != 'all day') {
          shortDay = dayName.substring(0, 3);
        }
        activeSchedules.add({'day': shortDay, 'time': displayTime});
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withAlpha(22), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Icon Frame
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _DoctorTheme.accent.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _DoctorTheme.accent.withAlpha(30),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _DoctorTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _DoctorTheme.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _DoctorTheme.accent.withAlpha(12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _DoctorTheme.accent.withAlpha(40),
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              desig,
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: _DoctorTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spec,
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _DoctorTheme.textSecondary,
                        ),
                      ),
                      if (more.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          more,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          // Seating schedule & actions bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONSULTATION FEE',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹$fees',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _DoctorTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'SEATING SCHEDULE',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (activeSchedules.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Flexible / Contact Chamber',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: activeSchedules.map<Widget>((sched) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _DoctorTheme.accent.withAlpha(12),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _DoctorTheme.accent.withAlpha(35),
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          '${sched['day']}: ${sched['time']}',
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _DoctorTheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                const Divider(
                  height: 16,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _navigateToAddDoctor(doctorToEdit: doc),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: _DoctorTheme.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit Details',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _DoctorTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _deleteDoctor(id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
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
    );
  }
}
