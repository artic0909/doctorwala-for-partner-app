import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'addtests.dart';

class _TestTheme {
  static const Color primary = Color(0xFF4C1D95); // Deep Biotech Purple/Violet
  static const Color accent = Color(0xFFD946EF); // Diagnostic Fuchsia/Orchid
  static const Color accentLight = Color(0xFFFAF5FF); // Soft Lavender
  static const Color bgTint = Color(0xFFFAF5FF); // Tint background
  static const Color textPrimary = Color(0xFF1E1B4B); // Deep indigo text
  static const Color textSecondary = Color(0xFF475569); // Slate secondary text
  static const Color border = Color(0xFFE9D5FF); // Soft purple border
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF4C1D95), Color(0xFFD946EF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _TestTheme.primary.withValues(alpha: 0.03),
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
                              'Pathology Tests',
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _TestTheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total tests configured: ${_tests.length}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _TestTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: _TestTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _TestTheme.accent.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToAddTest(),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Add Test',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: _TestTheme.bgTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _TestTheme.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _TestTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _TestTheme.accent,
                            size: 20,
                          ),
                          hintText: 'Search by test name or type...',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 13,
                            color: _TestTheme.textSecondary.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isFetching
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _TestTheme.accent,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchTests,
                        color: _TestTheme.accent,
                        child: _filteredTests.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
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

    List<dynamic> daysList = [];
    final scheduleData = test['test_day_time'];
    if (scheduleData != null) {
      if (scheduleData is List) {
        daysList = scheduleData;
      } else if (scheduleData is String) {
        try {
          daysList = jsonDecode(scheduleData);
        } catch (_) {}
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _TestTheme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _TestTheme.primary.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _TestTheme.accentLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _TestTheme.accent.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: _TestTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _TestTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _TestTheme.accentLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _TestTheme.accent.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          type,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _TestTheme.accent,
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
            padding: const EdgeInsets.all(16),
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
                        color: _TestTheme.textSecondary.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹$price',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _TestTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'AVAILABILITY HOURS',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _TestTheme.textSecondary.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (daysList.isEmpty)
                  Text(
                    'No schedule configured',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: daysList.map<Widget>((sched) {
                      final dayName = sched['day']?.toString() ?? '';
                      final start = sched['start_time']?.toString() ?? '';
                      final end = sched['end_time']?.toString() ?? '';

                      String shortDay = dayName;
                      if (dayName.length > 3 && dayName.toLowerCase() != 'all day') {
                        shortDay = dayName.substring(0, 3);
                      }

                      final startDisplay = _formatDBTime(start);
                      final endDisplay = _formatDBTime(end);
                      final String displayTime;
                      if (startDisplay.isEmpty && endDisplay.isEmpty) {
                        displayTime = 'No Timings';
                      } else if (endDisplay.isEmpty) {
                        displayTime = '$startDisplay onwards';
                      } else if (startDisplay.isEmpty) {
                        displayTime = 'Till $endDisplay';
                      } else {
                        displayTime = '$startDisplay - $endDisplay';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _TestTheme.accentLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _TestTheme.accent.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '$shortDay: $displayTime',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _TestTheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                const Divider(
                  height: 24,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToAddTest(testToEdit: test),
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: _TestTheme.accent,
                      ),
                      label: Text(
                        'Edit Details',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _TestTheme.accent,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteTest(id),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      label: Text(
                        'Remove',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
