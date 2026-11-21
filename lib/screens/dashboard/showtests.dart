import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'addtests.dart';
import '../../widgets/partner_skeleton_loader.dart';

class _TestTheme {
  static const Color primary = Color(0xFF4C1D95); // Deep Biotech Purple/Violet
  static const Color accent = Color(0xFFD946EF); // Diagnostic Fuchsia/Orchid
  static const Color accentLight = Color(0xFFFAF5FF); // Soft Lavender
  static const Color bgTint = Color(0xFFFAF5FF); // Tint background
  static const Color textPrimary = Color(0xFF1E1B4B); // Deep indigo text
  static const Color textSecondary = Color(0xFF475569); // Slate secondary text
}

class ShowTestsScreen extends StatefulWidget {
  const ShowTestsScreen({super.key});

  @override
  State<ShowTestsScreen> createState() => _ShowTestsScreenState();
}

class _ShowTestsScreenState extends State<ShowTestsScreen> {
  bool _isFetching = true;
  bool _isLoading = false;
  List<dynamic> _tests = [];
  List<dynamic> _filteredTests = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTests();
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
        _filteredTests = _tests;
      } else {
        _filteredTests = _tests.where((test) {
          final name = (test['test_name'] ?? '').toString().toLowerCase();
          final type = (test['test_type'] ?? '').toString().toLowerCase();
          return name.contains(query) || type.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchTests() async {
    if (!mounted) return;
    setState(() => _isFetching = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _isFetching = false);
        return;
      }

      final response = await ApiService.getTests(token: token);
      if (!mounted) return;
      if (response['success'] == true) {
        setState(() {
          _tests = response['tests'] ?? [];
          _filteredTests = _tests;
        });
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? 'Failed to load tests.',
        );
      }
    } catch (_) {
      if (mounted) {
        CustomAlerts.showError(
          context,
          'An unexpected error occurred while fetching tests.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _deleteTest(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Pathology Test',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: _TestTheme.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this test? It will be removed from your catalog.',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w500,
            color: _TestTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: _TestTheme.textSecondary,
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

        final res = await ApiService.deleteTest(token: token, id: id);
        if (!mounted) return;
        if (res['success'] == true) {
          CustomAlerts.showSuccess(
            context,
            res['message'] ?? 'Test deleted successfully!',
          );
          _fetchTests();
        } else {
          CustomAlerts.showError(
            context,
            res['message'] ?? 'Failed to delete test.',
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
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  void _navigateToAddTest({Map<String, dynamic>? testToEdit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTestsScreen(testToEdit: testToEdit),
      ),
    );
    if (result == true) {
      _fetchTests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TestTheme.bgTint,
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
                              'Pathology Tests',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _TestTheme.primary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total tests configured: ${_tests.length}',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _TestTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // Add Test Button
                        SizedBox(
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToAddTest(),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Add Test',
                              style: GoogleFonts.manrope(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
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
                          color: _TestTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          hintText: 'Search by test name or type...',
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
                              color: Color(0xFF7C3AED),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isFetching
                    ? const PartnerTestsSkeleton()
                    : RefreshIndicator(
                        onRefresh: _fetchTests,
                        color: _TestTheme.accent,
                        child: _filteredTests.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 14,
                                  bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
                                ),
                                itemCount: _filteredTests.length,
                                itemBuilder: (context, idx) {
                                  final test = _filteredTests[idx] as Map<String, dynamic>;
                                  return FadeInUp(
                                    duration: const Duration(milliseconds: 300),
                                    child: _buildTestCard(test),
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
                  valueColor: AlwaysStoppedAnimation<Color>(_TestTheme.accent),
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
                color: _TestTheme.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.science_rounded,
                color: _TestTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty ? 'No Tests Configured' : 'No Results Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _TestTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Tap "+ Add Test" at the top to configure your pathology test catalog.'
                  : 'We couldn\'t find any matches for "$query". Try typing a different name.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _TestTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final id = test['id']?.toString() ?? '';
    final name = test['test_name'] ?? 'N/A';
    final type = test['test_type'] ?? 'N/A';
    final price = test['test_price']?.toString() ?? '0';

    List<dynamic> rawDaysList = [];
    final scheduleData = test['test_day_time'];
    if (scheduleData != null) {
      if (scheduleData is List) {
        rawDaysList = scheduleData;
      } else if (scheduleData is String) {
        try {
          rawDaysList = jsonDecode(scheduleData);
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
                // Test Flask Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withAlpha(30),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Color(0xFF7C3AED),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _TestTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withAlpha(12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withAlpha(40),
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          type,
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TEST CHARGES',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹$price',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'AVAILABILITY HOURS',
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
                      'Flexible / Contact Lab',
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
                          color: const Color(0xFF7C3AED).withAlpha(12),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withAlpha(35),
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          '${sched['day']}: ${sched['time']}',
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _TestTheme.primary,
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
                      onTap: () => _navigateToAddTest(testToEdit: test),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit Details',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _deleteTest(id),
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
