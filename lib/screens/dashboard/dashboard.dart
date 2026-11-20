import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/session_manager.dart';
import '../../core/api_service.dart';
import 'widgets/bottom_nav.dart';
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
  int _profileCompletionPercent = 0;
  bool _step1Done = false;
  bool _step2Done = false;
  bool _step3Done = false;
  late Map<String, dynamic> _partnerData;

  @override
  void initState() {
    super.initState();
    _partnerData = widget.partnerData;
    _loadCachedProfileState();
    _fetchStats();
  }

  Future<void> _loadCachedProfileState() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = _partnerData['id']?.toString() ?? 'default';
    final types = _parseRegistrationTypes(_partnerData['registration_type']);
    final hasOPD = types.contains('OPD');
    final hasPathology = types.contains('Pathology');

    if (mounted) {
      final pct = prefs.getInt('profile_completion_percent_$partnerId') ?? 0;
      bool s1 = false, s2 = false, s3 = false;

      if (hasOPD && hasPathology) {
        s1 = (prefs.getBool('has_opd_info_$partnerId') ?? false) &&
            (prefs.getBool('has_opd_addr_$partnerId') ?? false) &&
            (prefs.getBool('has_opd_map_$partnerId') ?? false) &&
            (prefs.getBool('has_opd_banner_$partnerId') ?? false);
        s2 = (prefs.getBool('has_path_info_$partnerId') ?? false) &&
            (prefs.getBool('has_path_addr_$partnerId') ?? false) &&
            (prefs.getBool('has_path_map_$partnerId') ?? false) &&
            (prefs.getBool('has_path_banner_$partnerId') ?? false);
        s3 = prefs.getBool('has_doc_added_$partnerId') ?? false;
      } else if (hasOPD) {
        s1 = prefs.getBool('has_opd_info_$partnerId') ?? false;
        s2 = (prefs.getBool('has_opd_addr_$partnerId') ?? false) && (prefs.getBool('has_opd_map_$partnerId') ?? false);
        s3 = prefs.getBool('has_opd_banner_$partnerId') ?? false;
      } else if (hasPathology) {
        s1 = prefs.getBool('has_path_info_$partnerId') ?? false;
        s2 = (prefs.getBool('has_path_addr_$partnerId') ?? false) && (prefs.getBool('has_path_map_$partnerId') ?? false);
        s3 = prefs.getBool('has_path_banner_$partnerId') ?? false;
      } else {
        s1 = prefs.getBool('has_doc_info_$partnerId') ?? false;
        s2 = (prefs.getBool('has_fee_$partnerId') ?? false) && (prefs.getBool('has_sched_$partnerId') ?? false);
        s3 = (prefs.getBool('has_addr_$partnerId') ?? false) && (prefs.getBool('has_map_$partnerId') ?? false);
      }

      setState(() {
        _profileCompletionPercent = pct;
        _step1Done = s1;
        _step2Done = s2;
        _step3Done = s3;
      });
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

      final types = _parseRegistrationTypes(_partnerData['registration_type']);
      final hasOPD = types.contains('OPD');
      final hasPathology = types.contains('Pathology');
      final hasDoctor = types.contains('Doctor');

      final apiCalls = <Future<dynamic>>[
        ApiService.getDoctors(token: token).catchError((_) => {'success': false}),
        ApiService.getTests(token: token).catchError((_) => {'success': false}),
        ApiService.getAppointmentsStats(token: token).catchError((_) => {'success': false}),
        ApiService.getAppointments(token: token).catchError((_) => {'success': false}),
      ];

      if (hasDoctor) {
        apiCalls.add(ApiService.getClinicProfile(type: 'doctor', token: token).catchError((_) => {'success': false}));
      }
      if (hasOPD) {
        apiCalls.add(ApiService.getClinicProfile(type: 'opd', token: token).catchError((_) => {'success': false}));
      }
      if (hasPathology) {
        apiCalls.add(ApiService.getClinicProfile(type: 'pathology', token: token).catchError((_) => {'success': false}));
      }

      final results = await Future.wait(apiCalls);

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

      int nextProfileIdx = 4;
      Map<String, dynamic>? docProfile;
      Map<String, dynamic>? opdProfile;
      Map<String, dynamic>? pathProfile;

      if (hasDoctor && nextProfileIdx < results.length) {
        docProfile = results[nextProfileIdx] is Map<String, dynamic> ? results[nextProfileIdx] : null;
        nextProfileIdx++;
      }
      if (hasOPD && nextProfileIdx < results.length) {
        opdProfile = results[nextProfileIdx] is Map<String, dynamic> ? results[nextProfileIdx] : null;
        nextProfileIdx++;
      }
      if (hasPathology && nextProfileIdx < results.length) {
        pathProfile = results[nextProfileIdx] is Map<String, dynamic> ? results[nextProfileIdx] : null;
        nextProfileIdx++;
      }

      final prefs = await SharedPreferences.getInstance();
      final partnerId = _partnerData['id']?.toString() ?? 'default';

      bool s1 = false, s2 = false, s3 = false, s4 = false;
      int percent = 0;

      if (hasOPD && hasPathology) {
        bool opdInfo = prefs.getBool('has_opd_info_$partnerId') ?? false;
        bool opdAddr = prefs.getBool('has_opd_addr_$partnerId') ?? false;
        bool opdMap = prefs.getBool('has_opd_map_$partnerId') ?? false;
        bool opdBanner = prefs.getBool('has_opd_banner_$partnerId') ?? false;

        if (opdProfile != null && opdProfile['success'] == true && opdProfile['contact_details'] != null) {
          final cd = opdProfile['contact_details'] as Map<String, dynamic>;
          final name = (cd['clinic_name'] ?? _partnerData['partner_clinic_name'] ?? '').toString().trim();
          final regType = (cd['clinic_registration_type'] ?? '').toString().trim();
          final person = (cd['clinic_contact_person_name'] ?? _partnerData['partner_contact_person_name'] ?? '').toString().trim();
          final phone = (cd['clinic_mobile_number'] ?? _partnerData['partner_mobile_number'] ?? '').toString().trim();
          opdInfo = name.isNotEmpty && regType.isNotEmpty && person.isNotEmpty && phone.isNotEmpty;

          final addr = (cd['clinic_address'] ?? _partnerData['partner_address'] ?? '').toString().trim();
          final city = (cd['clinic_city'] ?? _partnerData['partner_city'] ?? '').toString().trim();
          final pin = (cd['clinic_pincode'] ?? _partnerData['partner_pincode'] ?? '').toString().trim();
          opdAddr = addr.isNotEmpty && city.isNotEmpty && pin.isNotEmpty;

          final mapLink = (cd['clinic_google_map_link'] ?? '').toString().trim();
          opdMap = mapLink.isNotEmpty;

          final bannerUrl = opdProfile['opd_banner'] ?? cd['opd_banner'];
          opdBanner = bannerUrl != null && bannerUrl.toString().trim().isNotEmpty;
        }

        bool pathInfo = prefs.getBool('has_path_info_$partnerId') ?? false;
        bool pathAddr = prefs.getBool('has_path_addr_$partnerId') ?? false;
        bool pathMap = prefs.getBool('has_path_map_$partnerId') ?? false;
        bool pathBanner = prefs.getBool('has_path_banner_$partnerId') ?? false;

        if (pathProfile != null && pathProfile['success'] == true && pathProfile['contact_details'] != null) {
          final cd = pathProfile['contact_details'] as Map<String, dynamic>;
          final name = (cd['clinic_name'] ?? _partnerData['partner_clinic_name'] ?? '').toString().trim();
          final regType = (cd['clinic_registration_type'] ?? '').toString().trim();
          final person = (cd['clinic_contact_person_name'] ?? _partnerData['partner_contact_person_name'] ?? '').toString().trim();
          final phone = (cd['clinic_mobile_number'] ?? _partnerData['partner_mobile_number'] ?? '').toString().trim();
          pathInfo = name.isNotEmpty && regType.isNotEmpty && person.isNotEmpty && phone.isNotEmpty;

          final addr = (cd['clinic_address'] ?? _partnerData['partner_address'] ?? '').toString().trim();
          final city = (cd['clinic_city'] ?? _partnerData['partner_city'] ?? '').toString().trim();
          final pin = (cd['clinic_pincode'] ?? _partnerData['partner_pincode'] ?? '').toString().trim();
          pathAddr = addr.isNotEmpty && city.isNotEmpty && pin.isNotEmpty;

          final mapLink = (cd['clinic_google_map_link'] ?? '').toString().trim();
          pathMap = mapLink.isNotEmpty;

          final bannerUrl = pathProfile['pathology_banner'] ?? cd['pathology_banner'];
          pathBanner = bannerUrl != null && bannerUrl.toString().trim().isNotEmpty;
        }

        final bool opdDone = opdInfo && opdAddr && opdMap && opdBanner;
        final bool pathDone = pathInfo && pathAddr && pathMap && pathBanner;
        final bool docAdded = docCount > 0;
        final bool testAdded = testCount > 0;

        s1 = opdDone;
        s2 = pathDone;
        s3 = docAdded;
        s4 = testAdded;

        int steps = 0;
        if (s1) steps++;
        if (s2) steps++;
        if (s3) steps++;
        if (s4) steps++;
        percent = steps * 25;

        await prefs.setInt('profile_completion_percent_$partnerId', percent);
        await prefs.setBool('has_opd_info_$partnerId', opdInfo);
        await prefs.setBool('has_opd_addr_$partnerId', opdAddr);
        await prefs.setBool('has_opd_map_$partnerId', opdMap);
        await prefs.setBool('has_opd_banner_$partnerId', opdBanner);
        await prefs.setBool('opd_contact_saved_$partnerId', opdDone);

        await prefs.setBool('has_path_info_$partnerId', pathInfo);
        await prefs.setBool('has_path_addr_$partnerId', pathAddr);
        await prefs.setBool('has_path_map_$partnerId', pathMap);
        await prefs.setBool('has_path_banner_$partnerId', pathBanner);
        await prefs.setBool('pathology_contact_saved_$partnerId', pathDone);

        await prefs.setBool('has_doc_added_$partnerId', s3);
        await prefs.setBool('has_test_added_$partnerId', s4);
      } else if (hasOPD) {
        bool opdInfo = prefs.getBool('has_opd_info_$partnerId') ?? false;
        bool opdAddrMap = (prefs.getBool('has_opd_addr_$partnerId') ?? false) && (prefs.getBool('has_opd_map_$partnerId') ?? false);
        bool opdBanner = prefs.getBool('has_opd_banner_$partnerId') ?? false;

        if (opdProfile != null && opdProfile['success'] == true && opdProfile['contact_details'] != null) {
          final cd = opdProfile['contact_details'] as Map<String, dynamic>;
          final name = (cd['clinic_name'] ?? _partnerData['partner_clinic_name'] ?? '').toString().trim();
          final regType = (cd['clinic_registration_type'] ?? '').toString().trim();
          final person = (cd['clinic_contact_person_name'] ?? _partnerData['partner_contact_person_name'] ?? '').toString().trim();
          final phone = (cd['clinic_mobile_number'] ?? _partnerData['partner_mobile_number'] ?? '').toString().trim();
          opdInfo = name.isNotEmpty && regType.isNotEmpty && person.isNotEmpty && phone.isNotEmpty;

          final addr = (cd['clinic_address'] ?? _partnerData['partner_address'] ?? '').toString().trim();
          final city = (cd['clinic_city'] ?? _partnerData['partner_city'] ?? '').toString().trim();
          final pin = (cd['clinic_pincode'] ?? _partnerData['partner_pincode'] ?? '').toString().trim();
          final mapLink = (cd['clinic_google_map_link'] ?? '').toString().trim();
          opdAddrMap = addr.isNotEmpty && city.isNotEmpty && pin.isNotEmpty && mapLink.isNotEmpty;

          final bannerUrl = opdProfile['opd_banner'] ?? cd['opd_banner'];
          opdBanner = bannerUrl != null && bannerUrl.toString().trim().isNotEmpty;
        }

        final bool docAdded = docCount > 0;

        s1 = opdInfo;
        s2 = opdAddrMap;
        s3 = opdBanner;
        s4 = docAdded;

        int steps = 0;
        if (s1) steps++;
        if (s2) steps++;
        if (s3) steps++;
        if (s4) steps++;
        percent = steps * 25;

        await prefs.setInt('profile_completion_percent_$partnerId', percent);
        await prefs.setBool('has_opd_info_$partnerId', s1);
        await prefs.setBool('has_opd_addr_$partnerId', s2);
        await prefs.setBool('has_opd_map_$partnerId', s2);
        await prefs.setBool('has_opd_banner_$partnerId', s3);
        await prefs.setBool('has_doc_added_$partnerId', s4);
        await prefs.setBool('opd_contact_saved_$partnerId', s1 && s2 && s3);
      } else if (hasPathology) {
        bool pathInfo = prefs.getBool('has_path_info_$partnerId') ?? false;
        bool pathAddrMap = (prefs.getBool('has_path_addr_$partnerId') ?? false) && (prefs.getBool('has_path_map_$partnerId') ?? false);
        bool pathBanner = prefs.getBool('has_path_banner_$partnerId') ?? false;

        if (pathProfile != null && pathProfile['success'] == true && pathProfile['contact_details'] != null) {
          final cd = pathProfile['contact_details'] as Map<String, dynamic>;
          final name = (cd['clinic_name'] ?? _partnerData['partner_clinic_name'] ?? '').toString().trim();
          final regType = (cd['clinic_registration_type'] ?? '').toString().trim();
          final person = (cd['clinic_contact_person_name'] ?? _partnerData['partner_contact_person_name'] ?? '').toString().trim();
          final phone = (cd['clinic_mobile_number'] ?? _partnerData['partner_mobile_number'] ?? '').toString().trim();
          pathInfo = name.isNotEmpty && regType.isNotEmpty && person.isNotEmpty && phone.isNotEmpty;

          final addr = (cd['clinic_address'] ?? _partnerData['partner_address'] ?? '').toString().trim();
          final city = (cd['clinic_city'] ?? _partnerData['partner_city'] ?? '').toString().trim();
          final pin = (cd['clinic_pincode'] ?? _partnerData['partner_pincode'] ?? '').toString().trim();
          final mapLink = (cd['clinic_google_map_link'] ?? '').toString().trim();
          pathAddrMap = addr.isNotEmpty && city.isNotEmpty && pin.isNotEmpty && mapLink.isNotEmpty;

          final bannerUrl = pathProfile['pathology_banner'] ?? cd['pathology_banner'];
          pathBanner = bannerUrl != null && bannerUrl.toString().trim().isNotEmpty;
        }

        final bool testAdded = testCount > 0;

        s1 = pathInfo;
        s2 = pathAddrMap;
        s3 = pathBanner;
        s4 = testAdded;

        int steps = 0;
        if (s1) steps++;
        if (s2) steps++;
        if (s3) steps++;
        if (s4) steps++;
        percent = steps * 25;

        await prefs.setInt('profile_completion_percent_$partnerId', percent);
        await prefs.setBool('has_path_info_$partnerId', s1);
        await prefs.setBool('has_path_addr_$partnerId', s2);
        await prefs.setBool('has_path_map_$partnerId', s2);
        await prefs.setBool('has_path_banner_$partnerId', s3);
        await prefs.setBool('has_test_added_$partnerId', s4);
        await prefs.setBool('pathology_contact_saved_$partnerId', s1 && s2 && s3);
      } else {
        bool hasDoc = prefs.getBool('has_doc_info_$partnerId') ?? false;
        bool hasFeeSched = (prefs.getBool('has_fee_$partnerId') ?? false) && (prefs.getBool('has_sched_$partnerId') ?? false);
        bool hasAddrMap = (prefs.getBool('has_addr_$partnerId') ?? false) && (prefs.getBool('has_map_$partnerId') ?? false);
        bool hasBanner = prefs.getBool('has_banner_$partnerId') ?? false;

        if (docProfile != null && docProfile['success'] == true && docProfile['contact_details'] != null) {
          final cd = docProfile['contact_details'] as Map<String, dynamic>;

          final name = (cd['partner_doctor_name'] ?? _partnerData['partner_contact_person_name'] ?? '').toString().trim();
          final spec = (cd['partner_doctor_specialist'] ?? '').toString().trim();
          final desig = (cd['partner_doctor_designation'] ?? '').toString().trim();
          hasDoc = name.isNotEmpty && spec.isNotEmpty && desig.isNotEmpty;

          final fees = double.tryParse((cd['partner_doctor_fees'] ?? '').toString().trim()) ?? 0;
          final bool schedOk = cd['visit_day_time'] != null && cd['visit_day_time'] is List && (cd['visit_day_time'] as List).isNotEmpty;
          hasFeeSched = fees > 0 && schedOk;

          final addr = (cd['partner_doctor_address'] ?? _partnerData['partner_address'] ?? '').toString().trim();
          final city = (cd['partner_doctor_city'] ?? _partnerData['partner_city'] ?? '').toString().trim();
          final pin = (cd['partner_doctor_pincode'] ?? _partnerData['partner_pincode'] ?? '').toString().trim();
          final mapLink = (cd['partner_doctor_google_map_link'] ?? '').toString().trim();
          hasAddrMap = addr.isNotEmpty && city.isNotEmpty && pin.isNotEmpty && mapLink.isNotEmpty;

          final bannerUrl = docProfile['doctor_banner'] ?? cd['partner_doctor_banner'];
          hasBanner = bannerUrl != null && bannerUrl.toString().trim().isNotEmpty;
        }

        s1 = hasDoc;
        s2 = hasFeeSched;
        s3 = hasAddrMap;
        s4 = hasBanner;

        int steps = 0;
        if (s1) steps++;
        if (s2) steps++;
        if (s3) steps++;
        if (s4) steps++;
        percent = steps * 25;

        await prefs.setInt('profile_completion_percent_$partnerId', percent);
        await prefs.setBool('has_doc_info_$partnerId', s1);
        await prefs.setBool('has_fee_$partnerId', s2);
        await prefs.setBool('has_sched_$partnerId', s2);
        await prefs.setBool('has_addr_$partnerId', s3);
        await prefs.setBool('has_map_$partnerId', s3);
        await prefs.setBool('has_banner_$partnerId', s4);
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
          _step1Done = s1;
          _step2Done = s2;
          _step3Done = s3;
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
          title: _currentIndex == 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Doctorwala ',
                              style: GoogleFonts.manrope(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.navy,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextSpan(
                              text: 'For Partner',
                              style: GoogleFonts.manrope(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  _currentIndex == 1
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

    final screenHeight = MediaQuery.sizeOf(context).height;
    final dynamicOverviewToCertGap = (screenHeight * 0.024).clamp(16.0, 26.0);
    final dynamicLabelToCardGap = (screenHeight * 0.012).clamp(8.0, 12.0);

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppColors.teal,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
        ),
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
            SizedBox(height: dynamicOverviewToCertGap),

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
            SizedBox(height: dynamicLabelToCardGap),

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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundShortcutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION HEADER
        FadeInUp(
          duration: const Duration(milliseconds: 350),
          child: Row(
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
                  final bool opdContactDone = (hasOPD && hasPathology)
                      ? _step1Done
                      : (_step1Done && _step2Done && _step3Done);
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.local_hospital_rounded,
                      title: 'OPD \nProfile',
                      color: const Color(0xFF0D9488),
                      isLocked: false,
                      badge: opdContactDone ? '100%' : null,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  );
                }

                // 3. Pathology Clinic (if Pathology)
                if (hasPathology) {
                  final bool pathContactDone = (hasOPD && hasPathology)
                      ? _step2Done
                      : (_step1Done && _step2Done && _step3Done);
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.medical_services_rounded,
                      title: 'Lab\n Profile',
                      color: const Color(0xFF9333EA),
                      isLocked: false,
                      badge: pathContactDone ? '100%' : null,
                      onTap: () => setState(() => _currentIndex = 4),
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
                      isLocked: false,
                      onTap: () => setState(() => _currentIndex = 5),
                    ),
                  );
                }

                // 5. Add Tests (if Pathology)
                if (hasPathology) {
                  shortcutWidgets.add(
                    _buildRoundShortcutItem(
                      icon: Icons.science_rounded,
                      title: 'Add\n Lab Tests',
                      color: const Color(0xFF7C3AED),
                      isLocked: false,
                      onTap: () => setState(() => _currentIndex = 6),
                    ),
                  );
                }

                // 6. Medical Card Access
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.credit_card_rounded,
                    title: 'Medical\nCard',
                    color: const Color(0xFFE11D48),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 7),
                  ),
                );

                // 7. Patient Lists
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.people_alt_rounded,
                    title: 'Patient\nLists',
                    color: const Color(0xFF0284C7),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 8),
                  ),
                );

                // 8. Upcoming Appointments
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.pending_actions_rounded,
                    title: 'Upcoming\nAppts',
                    color: const Color(0xFFD97706),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                );

                // 9. Today's Bookings
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.calendar_month_rounded,
                    title: "Today's\nBookings",
                    color: const Color(0xFF059669),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 15),
                  ),
                );

                // 10. Completed Appointments
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.task_alt_rounded,
                    title: 'Completed\nAppts',
                    color: const Color(0xFF10B981),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 9),
                  ),
                );

                // 11. Cancelled Appointments
                shortcutWidgets.add(
                  _buildRoundShortcutItem(
                    icon: Icons.cancel_rounded,
                    title: 'Cancelled\nAppts',
                    color: const Color(0xFFDC2626),
                    isLocked: false,
                    onTap: () => setState(() => _currentIndex = 14),
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
