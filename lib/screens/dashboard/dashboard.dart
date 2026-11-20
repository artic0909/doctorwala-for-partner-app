import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/session_manager.dart';
import '../../core/api_service.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/onboarding_tutorial_dialog.dart';
import 'opdcontact.dart';
import 'pathologycontact.dart';
import 'doctocontact.dart';
import 'showdoctors.dart';
import 'showtests.dart';
import 'appointments/upcoming.dart';
import 'appointments/complete.dart';
import 'appointments/cancel.dart';
import 'appointments/today.dart';
import 'account_settings.dart';
import 'notifications.dart';
import 'help.dart';
import 'medical_card_access.dart';
import 'patient_lists.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const DashboardScreen({super.key, required this.partnerData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  int _totalDoctors = 0;
  int _totalTests = 0;
  int _upcomingCount = 0;
  int _completedCount = 0;
  int _todayCount = 0;
  bool _isFetchingStats = false;
  bool _hasUnreadNotifications = false;
  bool _isTutorialBannerDismissed = false;
  int _profileCompletionPercent = 0;
  bool _hasDoctorInfo = false;
  bool _hasFees = false;
  bool _hasAddress = false;
  bool _hasSchedule = false;
  late Map<String, dynamic> _partnerData;

  @override
  void initState() {
    super.initState();
    _partnerData = widget.partnerData;
    _loadCachedProfileState();
    _fetchStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _loadCachedProfileState() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = _partnerData['id']?.toString() ?? 'default';
    if (mounted) {
      final pct = prefs.getInt('profile_completion_percent_$partnerId') ?? 0;
      setState(() {
        _profileCompletionPercent = pct;
        _hasDoctorInfo = prefs.getBool('has_doc_info_$partnerId') ?? false;
        _hasFees = prefs.getBool('has_fee_$partnerId') ?? false;
        _hasAddress = prefs.getBool('has_addr_$partnerId') ?? false;
        _hasSchedule = prefs.getBool('has_sched_$partnerId') ?? false;
      });
    }
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool dismissed =
        prefs.getBool('dismiss_onboarding_tutorial_v1') ?? false;
    final partnerId = _partnerData['id']?.toString() ?? 'default';
    final int pct = prefs.getInt('profile_completion_percent_$partnerId') ?? 0;

    if (!dismissed && pct < 100 && mounted) {
      OnboardingTutorialDialog.show(
        context,
        autoTriggered: true,
        onStartSetup: () {
          setState(() {
            _currentIndex = 11;
          });
        },
      );
    }
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isFetchingStats = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) setState(() => _isFetchingStats = false);
        return;
      }

      final results = await Future.wait([
        ApiService.getDoctors(token: token).catchError((_) => {'success': false}),
        ApiService.getTests(token: token).catchError((_) => {'success': false}),
        ApiService.getAppointmentsStats(token: token).catchError((_) => {'success': false}),
        ApiService.getAppointments(token: token).catchError((_) => {'success': false}),
        ApiService.getClinicProfile(type: 'doctor', token: token).catchError((_) => {'success': false}),
      ]);

      final doctorsRes = results[0];
      final testsRes = results[1];
      final statsRes = results[2];
      final apptsRes = results[3];
      final profileRes = results[4];

      int docCount = 0;
      int testCount = 0;
      int upcoming = 0;
      int completed = 0;
      int today = 0;
      bool hasUnread = false;

      if (doctorsRes['success'] == true && doctorsRes['doctors'] != null) {
        docCount = (doctorsRes['doctors'] as List).length;
      }
      if (testsRes['success'] == true && testsRes['tests'] != null) {
        testCount = (testsRes['tests'] as List).length;
      }
      if (statsRes['success'] == true && statsRes['stats'] != null) {
        final s = statsRes['stats'];
        upcoming = s['upcoming_count'] ?? 0;
        completed = s['completed_count'] ?? 0;
        today = s['today_count'] ?? 0;
      }
      if (apptsRes['success'] == true && apptsRes['appointments'] != null) {
        final List<dynamic> appts = apptsRes['appointments'];
        final prefs = await SharedPreferences.getInstance();
        final readIds = (prefs.getStringList('partner_read_booking_ids') ?? []).toSet();
        hasUnread = appts.any((appt) => !readIds.contains(appt['id']?.toString() ?? ''));
      }

      // Check accurate 4-milestone doctor profile completion
      final prefs = await SharedPreferences.getInstance();
      final partnerId = _partnerData['id']?.toString() ?? 'default';

      int percent = prefs.getInt('profile_completion_percent_$partnerId') ?? 0;
      bool hasDoc = prefs.getBool('has_doc_info_$partnerId') ?? false;
      bool hasFee = prefs.getBool('has_fee_$partnerId') ?? false;
      bool hasAddr = prefs.getBool('has_addr_$partnerId') ?? false;
      bool hasSched = prefs.getBool('has_sched_$partnerId') ?? false;

      if (profileRes['success'] == true && profileRes['contact_details'] != null) {
        final cd = profileRes['contact_details'] as Map<String, dynamic>;

        final name = (cd['partner_doctor_name'] ?? _partnerData['partner_contact_person_name'] ?? '').toString().trim();
        final spec = (cd['partner_doctor_specialist'] ?? '').toString().trim();
        final desig = (cd['partner_doctor_designation'] ?? '').toString().trim();
        hasDoc = name.isNotEmpty && spec.isNotEmpty && desig.isNotEmpty;

        final fees = double.tryParse((cd['partner_doctor_fees'] ?? '').toString().trim()) ?? 0;
        hasFee = fees > 0;

        final addr = (cd['partner_doctor_address'] ?? _partnerData['partner_address'] ?? '').toString().trim();
        final city = (cd['partner_doctor_city'] ?? _partnerData['partner_city'] ?? '').toString().trim();
        final pin = (cd['partner_doctor_pincode'] ?? _partnerData['partner_pincode'] ?? '').toString().trim();
        hasAddr = addr.isNotEmpty && city.isNotEmpty && pin.isNotEmpty;

        hasSched = false;
        if (cd['visit_day_time'] != null && cd['visit_day_time'] is List) {
          final list = cd['visit_day_time'] as List;
          if (list.isNotEmpty) {
            hasSched = true;
          }
        }

        int steps = 0;
        if (hasDoc) steps++;
        if (hasFee) steps++;
        if (hasAddr) steps++;
        if (hasSched) steps++;
        percent = steps * 25;

        await prefs.setInt('profile_completion_percent_$partnerId', percent);
        await prefs.setBool('has_doc_info_$partnerId', hasDoc);
        await prefs.setBool('has_fee_$partnerId', hasFee);
        await prefs.setBool('has_addr_$partnerId', hasAddr);
        await prefs.setBool('has_sched_$partnerId', hasSched);
        await prefs.setBool('doctor_contact_saved_$partnerId', percent == 100);
      }

      if (mounted) {
        setState(() {
          _totalDoctors = docCount;
          _totalTests = testCount;
          _upcomingCount = upcoming;
          _completedCount = completed;
          _todayCount = today;
          _hasUnreadNotifications = hasUnread;
          _profileCompletionPercent = percent;
          _hasDoctorInfo = hasDoc;
          _hasFees = hasFee;
          _hasAddress = hasAddr;
          _hasSchedule = hasSched;
          _isFetchingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFetchingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: _currentIndex != 0
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.navy,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                )
              : null,
          shape: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.navy),
          title: Text(
            _currentIndex == 0
                ? 'Dashboard'
                : _currentIndex == 1
                ? 'Upcoming Appointments'
                : _currentIndex == 2
                ? 'Account Settings'
                : _currentIndex == 3
                ? 'Add Doctor Chamber'
                : _currentIndex == 4
                ? 'Add Pathology Clinic'
                : _currentIndex == 5
                ? 'Doctors Directory'
                : _currentIndex == 6
                ? 'Tests Catalog'
                : _currentIndex == 7
                ? 'Medical Card Access'
                : _currentIndex == 8
                ? 'Patient Lists'
                : _currentIndex == 9
                ? 'Complete Appointments'
                : _currentIndex == 11
                ? 'List Myself'
                : _currentIndex == 14
                ? 'Cancelled Appointments'
                : _currentIndex == 15
                ? "Today's Bookings"
                : 'Help & Support',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.navy,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(partnerData: _partnerData),
                        ),
                      ).then((_) => _fetchStats());
                    },
                  ),
                  if (_hasUnreadNotifications)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _currentIndex,
          partnerData: _partnerData,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return UpcomingAppointmentsScreen(partnerData: _partnerData);
      case 2:
        return AccountSettingsScreen(
          partnerData: _partnerData,
          onProfileUpdated: (updatedData) {
            setState(() {
              _partnerData = updatedData;
            });
          },
        );
      case 3:
        return const OpdContactScreen();
      case 4:
        return const PathologyContactScreen();
      case 5:
        return const ShowDoctorsScreen();
      case 6:
        return const ShowTestsScreen();
      case 7:
        return MedicalCardAccessTab(
          partnerData: _partnerData,
          onRequestSent: () {
            setState(() {
              _currentIndex = 8;
            });
          },
        );
      case 8:
        return PatientListsTab(partnerData: _partnerData);
      case 9:
        return CompleteAppointmentsScreen(partnerData: _partnerData);
      case 10:
        return HelpScreen(partnerData: _partnerData);
      case 11:
        return const DoctorContactScreen();
      case 14:
        return CancelledAppointmentsScreen(partnerData: _partnerData);
      case 15:
        return TodayAppointmentsScreen(partnerData: _partnerData, isTab: true);
      default:
        return _buildHomeTab();
    }
  }

  // TAB 0: HOME / COUNTING CARDS
  Widget _buildWelcomeHeader(String clinicName, String contactPerson) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1E3A8A), // Indigo Navy
              Color(0xFF0F172A), // Slate Dark
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -15,
              child: Icon(
                Icons.health_and_safety_rounded,
                size: 90,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: AppColors.teal,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HEALTHCARE PARTNER NETWORK',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  clinicName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Representative: $contactPerson',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 13,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Partner ID: ${_partnerData['partner_id'] ?? 'N/A'}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 0: HOME / COUNTING CARDS
  Widget _buildHomeTab() {
    final clinicName = _partnerData['partner_clinic_name'] ?? 'N/A';
    final contactPerson =
        _partnerData['partner_contact_person_name'] ?? 'N/A';

    final rawRegType = _partnerData['registration_type'];
    final types = _parseRegistrationTypes(rawRegType);
    final hasOPD = types.contains('OPD');
    final hasPathology = types.contains('Pathology');

    final cards = <Widget>[
      _buildCountCard(
        title: "Today's Appointments",
        count: '$_todayCount',
        icon: Icons.today_rounded,
        color: AppColors.teal,
        delayMs: 100,
        isLoading: _isFetchingStats,
        onTap: () {
          setState(() {
            _currentIndex = 15;
          });
        },
      ),
      _buildCountCard(
        title: 'Pending Appts',
        count: '$_upcomingCount',
        icon: Icons.pending_actions_rounded,
        color: Colors.orangeAccent,
        delayMs: 150,
        isLoading: _isFetchingStats,
        onTap: () {
          setState(() {
            _currentIndex = 1; // Upcoming Appointments
          });
        },
      ),
      _buildCountCard(
        title: 'Completed Appts',
        count: '$_completedCount',
        icon: Icons.task_alt_rounded,
        color: Colors.blueAccent,
        delayMs: 200,
        isLoading: _isFetchingStats,
        onTap: () {
          setState(() {
            _currentIndex = 9; // Completed Appointments
          });
        },
      ),
      if (hasOPD)
        _buildCountCard(
          title: 'Total Doctors',
          count: '$_totalDoctors',
          icon: Icons.people_alt_rounded,
          color: AppColors.navy,
          delayMs: 250,
          isLoading: _isFetchingStats,
          onTap: () {
            setState(() {
              _currentIndex = 5; // Show Doctors Directory
            });
          },
        ),
      if (hasPathology)
        _buildCountCard(
          title: 'Pathology Tests',
          count: '$_totalTests',
          icon: Icons.biotech_rounded,
          color: Colors.purpleAccent,
          delayMs: 300,
          isLoading: _isFetchingStats,
          onTap: () {
            setState(() {
              _currentIndex = 6; // Show Tests Catalog
            });
          },
        ),
    ];

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppColors.teal,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(clinicName, contactPerson),
            const SizedBox(height: 12),

            // ROUND SHORTCUTS & TUTORIAL ONBOARDING SECTION
            _buildRoundShortcutsSection(),
            const SizedBox(height: 14),

            // Overview Header
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dashboard Overview',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Counting Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: MediaQuery.sizeOf(context).width < 360
                  ? 1.30
                  : (MediaQuery.sizeOf(context).width < 400 ? 1.45 : 1.55),
              children: cards,
            ),
            const SizedBox(height: 14),

            // Certificate Section Label
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verification Status',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Header / Welcome Certificate banner
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF6), // Cream certificate background
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFD4AF37), // Metallic Gold
                    width: 2.5,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Logo & Stamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 30,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.teal,
                              size: 28,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFFC59B27),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'VERIFIED',
                                  style: GoogleFonts.manrope(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFC59B27),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Certificate Title
                      Text(
                        'CERTIFICATE OF PARTNERSHIP',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFC59B27),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is proudly presented to',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.navy.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Partner/Clinic Name
                      Text(
                        clinicName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Partnership Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'as a certified healthcare service partner under the Doctorwala Network.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      
                      // Signature / Footer Row with award.png
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PARTNER ID',
                                    style: GoogleFonts.manrope(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.partnerData['partner_id'] ?? 'N/A',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Official Award Seal/Stamp Image
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Image.asset(
                                'assets/images/award.png',
                                height: 48,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xFFD4AF37),
                                  size: 40,
                                ),
                              ),
                            ),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'REPRESENTATIVE',
                                    style: GoogleFonts.manrope(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    contactPerson,
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundShortcutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ACCURATE PROFILE COMPLETION PROGRESS CARD (Hides when 100% complete)
        if (_profileCompletionPercent < 100 && !_isTutorialBannerDismissed)
          FadeInDown(
            duration: const Duration(milliseconds: 350),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _profileCompletionPercent == 100
                      ? [const Color(0xFFF0FDF4), const Color(0xFFF8FAFC)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFF0FDF9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _profileCompletionPercent == 100
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFF6366F1).withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_profileCompletionPercent == 100
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF6366F1))
                        .withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Percentage Badge, Status & Close (✖)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _profileCompletionPercent == 100
                              ? const Color(0xFF16A34A)
                              : (_profileCompletionPercent >= 50
                                  ? const Color(0xFF4F46E5)
                                  : Colors.orange.shade800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_profileCompletionPercent%',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profileCompletionPercent == 100
                                  ? 'Profile 100% Completed 🎉'
                                  : 'Profile Completion: $_profileCompletionPercent%',
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              _profileCompletionPercent == 100
                                  ? 'All services unlocked & ready to use'
                                  : 'Complete 4 steps to unlock all features',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dismiss / Close
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _isTutorialBannerDismissed = true);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Linear Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_profileCompletionPercent / 100.0).clamp(0.04, 1.0),
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _profileCompletionPercent == 100
                            ? const Color(0xFF16A34A)
                            : (_profileCompletionPercent >= 50
                                ? AppColors.teal
                                : Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4 Redirectable Checklist Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildRedirectableChip(
                        label: 'Doctor Info',
                        isDone: _hasDoctorInfo,
                        onTap: () => setState(() => _currentIndex = 11),
                      ),
                      _buildRedirectableChip(
                        label: 'Fees (INR)',
                        isDone: _hasFees,
                        onTap: () => setState(() => _currentIndex = 11),
                      ),
                      _buildRedirectableChip(
                        label: 'Chamber Address',
                        isDone: _hasAddress,
                        onTap: () => setState(() => _currentIndex = 11),
                      ),
                      _buildRedirectableChip(
                        label: 'Visiting Schedule',
                        isDone: _hasSchedule,
                        onTap: () => setState(() => _currentIndex = 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          OnboardingTutorialDialog.show(
                            context,
                            onStartSetup: () {
                              setState(() => _currentIndex = 11);
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.school_rounded, size: 14),
                        label: Text(
                          'Quick Guide',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _currentIndex = 11);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _profileCompletionPercent == 100
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                          icon: Icon(
                            _profileCompletionPercent == 100
                                ? Icons.edit_note_rounded
                                : Icons.arrow_forward_rounded,
                            size: 15,
                          ),
                          label: Text(
                            _profileCompletionPercent == 100
                                ? 'Update Profile'
                                : 'Complete Setup Now',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // SECTION HEADER
        FadeInUp(
          duration: const Duration(milliseconds: 350),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1), // Royal Indigo
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Shortcuts',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              // TUTORIAL & GUIDE POPUP BUTTON
              InkWell(
                onTap: () {
                  OnboardingTutorialDialog.show(
                    context,
                    onStartSetup: () {
                      setState(() => _currentIndex = 11);
                    },
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 13,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tutorial & Guide',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ALL ROUND SHORTCUTS FROM SIDEBAR GRID CONTAINER (Patient App Style)
        FadeInUp(
          duration: const Duration(milliseconds: 350),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blueGrey.withAlpha(20),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Builder(
              builder: (context) {
                final rawRegType = _partnerData['registration_type'];
                final types = _parseRegistrationTypes(rawRegType);
                final hasOPD = types.contains('OPD');
                final hasPathology = types.contains('Pathology');
                final hasDoctor = types.contains('Doctor');
                final isLocked = _profileCompletionPercent < 100;

                final List<Widget> shortcutWidgets = [];

                // 1. Doctor Profile / Complete Profile
                if (hasDoctor) {
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.assignment_ind_rounded,
                      title: 'Complete\nProfile',
                      color: const Color(0xFF4F46E5),
                      isLocked: false,
                      badge: _profileCompletionPercent == 100
                          ? '100%'
                          : '$_profileCompletionPercent%',
                      onTap: () => setState(() => _currentIndex = 11),
                    ),
                  );
                }

                // 2. Doctor Chamber (if OPD)
                if (hasOPD) {
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.local_hospital_rounded,
                      title: 'Doctor\nChamber',
                      color: const Color(0xFF0D9488),
                      isLocked: isLocked,
                      onTap: () {
                        if (isLocked) {
                          _showProfileRequiredDialog('Doctor Chamber');
                          return;
                        }
                        setState(() => _currentIndex = 3);
                      },
                    ),
                  );
                }

                // 3. Pathology Clinic (if Pathology)
                if (hasPathology) {
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.medical_services_rounded,
                      title: 'Pathology\nClinic',
                      color: const Color(0xFF9333EA),
                      isLocked: isLocked,
                      onTap: () {
                        if (isLocked) {
                          _showProfileRequiredDialog('Pathology Clinic');
                          return;
                        }
                        setState(() => _currentIndex = 4);
                      },
                    ),
                  );
                }

                // 4. Add Doctors (if OPD)
                if (hasOPD) {
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.person_add_rounded,
                      title: 'Add\nDoctors',
                      color: const Color(0xFF2563EB),
                      isLocked: isLocked,
                      onTap: () {
                        if (isLocked) {
                          _showProfileRequiredDialog('Doctors Directory');
                          return;
                        }
                        setState(() => _currentIndex = 5);
                      },
                    ),
                  );
                }

                // 5. Add Tests (if Pathology)
                if (hasPathology) {
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.science_rounded,
                      title: 'Add\nTests',
                      color: const Color(0xFF7C3AED),
                      isLocked: isLocked,
                      onTap: () {
                        if (isLocked) {
                          _showProfileRequiredDialog('Tests Catalog');
                          return;
                        }
                        setState(() => _currentIndex = 6);
                      },
                    ),
                  );
                }

                // 6. Medical Card Access
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.credit_card_rounded,
                    title: 'Medical\nCard',
                    color: const Color(0xFFE11D48),
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        _showProfileRequiredDialog('Medical Card Access');
                        return;
                      }
                      setState(() => _currentIndex = 7);
                    },
                  ),
                );

                // 7. Patient Lists
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.people_alt_rounded,
                    title: 'Patient\nLists',
                    color: const Color(0xFF0284C7),
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        _showProfileRequiredDialog('Patient Lists');
                        return;
                      }
                      setState(() => _currentIndex = 8);
                    },
                  ),
                );

                // 8. Upcoming Appointments
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.pending_actions_rounded,
                    title: 'Upcoming\nAppts',
                    color: const Color(0xFFD97706),
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        _showProfileRequiredDialog('Upcoming Appointments');
                        return;
                      }
                      setState(() => _currentIndex = 1);
                    },
                  ),
                );

                // 9. Today's Bookings
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.calendar_month_rounded,
                    title: "Today's\nBookings",
                    color: const Color(0xFF059669),
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        _showProfileRequiredDialog("Today's Bookings");
                        return;
                      }
                      setState(() => _currentIndex = 15);
                    },
                  ),
                );

                // 10. Completed Appointments
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.task_alt_rounded,
                    title: 'Completed\nAppts',
                    color: const Color(0xFF10B981),
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        _showProfileRequiredDialog('Completed Appointments');
                        return;
                      }
                      setState(() => _currentIndex = 9);
                    },
                  ),
                );

                // 11. Cancelled Appointments
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.cancel_rounded,
                    title: 'Cancelled\nAppts',
                    color: const Color(0xFFDC2626),
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        _showProfileRequiredDialog('Cancelled Appointments');
                        return;
                      }
                      setState(() => _currentIndex = 14);
                    },
                  ),
                );

                // 12. Account Settings
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Account\nSettings',
                    color: const Color(0xFF475569),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                );

                // 13. Help & Support
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help &\nSupport',
                    color: const Color(0xFF6366F1),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 10),
                  ),
                );

                // Group into rows of 4 items each (like patient app)
                final List<List<Widget>> rows = [];
                for (var i = 0; i < shortcutWidgets.length; i += 4) {
                  final end = (i + 4 < shortcutWidgets.length)
                      ? i + 4
                      : shortcutWidgets.length;
                  final chunk = shortcutWidgets.sublist(i, end);
                  while (chunk.length < 4) {
                    chunk.add(const Expanded(child: SizedBox()));
                  }
                  rows.add(chunk);
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int r = 0; r < rows.length; r++) ...[
                      if (r > 0) const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: rows[r],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedirectableChip({
    required String label,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.pending_rounded,
              size: 12,
              color: isDone ? const Color(0xFF16A34A) : Colors.orange.shade800,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDone ? const Color(0xFF15803D) : Colors.orange.shade900,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 12,
              color: isDone ? const Color(0xFF15803D) : Colors.orange.shade900,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundShortcutItem({
    required IconData icon,
    required String title,
    required Color color,
    required bool isLocked,
    String? badge,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final outerSize = isCompact ? 50.0 : 54.0;
    final innerSize = isCompact ? 36.0 : 40.0;
    final iconSize = isCompact ? 19.0 : 21.5;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Patient app style: Pure white outer circle with soft shadow & neutral border (no outer color tint)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: outerSize,
                  height: outerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: isLocked
                          ? const Color(0xFFE2E8F0)
                          : Colors.blueGrey.withAlpha(20),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      if (!isLocked)
                        BoxShadow(
                          color: color.withAlpha(18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLocked
                            ? const Color(0xFFF1F5F9)
                            : color.withAlpha(18),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: isLocked ? const Color(0xFF94A3B8) : color,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ),
                ),

                // Lock badge on bottom-right if locked
                if (isLocked)
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 9.5,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Top badge (e.g. START or 100%)
                if (badge != null)
                  Positioned(
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badge == 'START' ? const Color(0xFF4F46E5) : AppColors.teal,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.manrope(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Text Label below icon (matching patient app font and styling)
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: isCompact ? 9.5 : 10.5,
                fontWeight: isLocked ? FontWeight.w600 : FontWeight.w700,
                color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                height: 1.15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileRequiredDialog(String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Feature Locked',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          'Your profile is currently $_profileCompletionPercent% complete.\n\nPlease complete all 4 steps to 100% under "List Myself" to unlock $featureName and access all partner features.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              OnboardingTutorialDialog.show(
                context,
                onStartSetup: () {
                  setState(() => _currentIndex = 11);
                },
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFF6366F1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'View Guide 📖',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentIndex = 11);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'List Myself Now',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required int delayMs,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final cardHPad = isCompact ? 9.0 : 12.0;
    final cardVPad = isCompact ? 9.0 : 12.0;
    final countFontSize = isCompact ? 19.0 : 22.0;

    return FadeInUp(
      delay: Duration(milliseconds: delayMs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: cardHPad, vertical: cardVPad),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: color.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppColors.navy.withValues(alpha: 0.3),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.teal,
                              ),
                            ),
                          )
                        : Text(
                            count,
                            style: GoogleFonts.manrope(
                              fontSize: countFontSize,
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy,
                              height: 1.1,
                            ),
                          ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
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






  List<String> _parseRegistrationTypes(dynamic rawType) {
    if (rawType == null) return [];
    if (rawType is List) {
      return rawType.map((e) => e.toString().trim()).toList();
    }
    final str = rawType.toString().trim();
    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).toList();
        }
      } catch (_) {}
      // fallback manual parse
      final clean = str
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('\\', '');
      return clean
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [str];
  }
}
