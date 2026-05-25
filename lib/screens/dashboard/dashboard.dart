import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/session_manager.dart';
import '../../core/api_service.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/sidebar.dart';
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
  late Map<String, dynamic> _partnerData;

  @override
  void initState() {
    super.initState();
    _partnerData = widget.partnerData;
    _fetchStats();
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
      ]);

      final doctorsRes = results[0];
      final testsRes = results[1];
      final statsRes = results[2];
      final apptsRes = results[3];

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

      if (mounted) {
        setState(() {
          _totalDoctors = docCount;
          _totalTests = testCount;
          _upcomingCount = upcoming;
          _completedCount = completed;
          _todayCount = today;
          _hasUnreadNotifications = hasUnread;
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
        drawer: CustomSidebar(
          partnerData: _partnerData,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        body: _buildBody(),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _currentIndex,
          partnerData: _partnerData,
          onTap: (index) {
            if (index == -1) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
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
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(clinicName, contactPerson),
            const SizedBox(height: 25),

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
            const SizedBox(height: 12),

            // Counting Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: cards,
            ),
            const SizedBox(height: 25),

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
            const SizedBox(height: 12),

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
            const SizedBox(height: 30),
          ],
        ),
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
    return FadeInUp(
      delay: Duration(milliseconds: delayMs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                              fontSize: 22,
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
