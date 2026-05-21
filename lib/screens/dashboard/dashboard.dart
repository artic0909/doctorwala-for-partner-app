import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/sidebar.dart';
import 'opdcontact.dart';
import 'pathologycontact.dart';
import 'doctocontact.dart';
import 'adddoctor.dart';
import 'addtests.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const DashboardScreen({super.key, required this.partnerData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: Text(
          _currentIndex == 0
              ? 'Dashboard'
              : _currentIndex == 1
              ? 'Pending Appointments'
              : _currentIndex == 2
              ? 'Account Settings'
              : _currentIndex == 3
              ? 'Add Doctor Chamber'
              : _currentIndex == 4
              ? 'Add Pathology Clinic'
              : _currentIndex == 5
              ? 'Add Doctors'
              : _currentIndex == 6
              ? 'Add Test'
              : _currentIndex == 7
              ? 'Medical Card Access'
              : _currentIndex == 8
              ? 'Patient Lists'
              : _currentIndex == 9
              ? 'Complete Appointments'
              : _currentIndex == 11
              ? 'List Myself'
              : 'Help & Support',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.navy,
                  size: 24,
                ),
                onPressed: () {
                  // Dummy callback
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Center(
                    child: Text(
                      '0',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: CustomSidebar(
        partnerData: widget.partnerData,
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildPendingAppointmentsTab();
      case 2:
        return _buildProfileTab(); // Profile serves as Account Settings
      case 3:
        return const OpdContactScreen();
      case 4:
        return const PathologyContactScreen();
      case 5:
        return const AddDoctorScreen();
      case 6:
        return const AddTestsScreen();
      case 7:
        return _buildPlaceholderTab('Medical Card Access', Icons.badge_rounded);
      case 8:
        return _buildPlaceholderTab('Patient Lists', Icons.assignment_rounded);
      case 9:
        return _buildPlaceholderTab(
          'Complete Appointments',
          Icons.task_alt_rounded,
        );
      case 10:
        return _buildPlaceholderTab(
          'Help & Support',
          Icons.help_outline_rounded,
        );
      case 11:
        return const DoctorContactScreen();
      default:
        return _buildHomeTab();
    }
  }

  // TAB 0: HOME / COUNTING CARDS
  Widget _buildHomeTab() {
    final clinicName = widget.partnerData['partner_clinic_name'] ?? 'N/A';
    final contactPerson =
        widget.partnerData['partner_contact_person_name'] ?? 'N/A';

    final rawRegType = widget.partnerData['registration_type'];
    final types = _parseRegistrationTypes(rawRegType);
    final hasOPD = types.contains('OPD');
    final hasPathology = types.contains('Pathology');

    final cards = <Widget>[
      _buildCountCard(
        title: "Today's Appointments",
        count: '0',
        icon: Icons.today_rounded,
        color: AppColors.teal,
        delayMs: 300,
      ),
      _buildCountCard(
        title: 'Pending Appts',
        count: '0',
        icon: Icons.pending_actions_rounded,
        color: Colors.orangeAccent,
        delayMs: 400,
      ),
      _buildCountCard(
        title: 'Completed Appts',
        count: '0',
        icon: Icons.task_alt_rounded,
        color: Colors.blueAccent,
        delayMs: 500,
      ),
      if (hasOPD)
        _buildCountCard(
          title: 'Total Doctors',
          count: '0',
          icon: Icons.people_alt_rounded,
          color: AppColors.navy,
          delayMs: 600,
        ),
      if (hasPathology)
        _buildCountCard(
          title: 'Pathology Tests',
          count: '0',
          icon: Icons.biotech_rounded,
          color: Colors.purpleAccent,
          delayMs: 700,
        ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Header
          FadeIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Dashboard Overview',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Counting Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: cards,
          ),
          const SizedBox(height: 25),

          // Certificate Section Label
          FadeIn(
            delay: const Duration(milliseconds: 250),
            child: Text(
              'Verification Certificate',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Header / Welcome Certificate banner (Medical Theme)
          Builder(
            builder: (context) {
              // Parse dynamic certificate text based on registration types
              String certTitle = 'CLINICAL NETWORK CERTIFICATE';
              String certDesc =
                  'is certified as an official healthcare partner under the Doctorwala Network, authorized to manage digital clinics and patient services.';

              final isOPD = types.contains('OPD');
              final isPathology = types.contains('Pathology');
              final isDoctor = types.contains('Doctor');

              if (isOPD && isPathology && isDoctor) {
                certTitle = 'INTEGRATED CLINICAL CERTIFICATE';
                certDesc =
                    'is officially certified to manage doctor chambers, digital OPD services, clinical pathology lab diagnostics, and comprehensive patient consulting under Doctorwala.';
              } else if (isOPD && isPathology) {
                certTitle = 'CLINICAL & DIAGNOSTIC CERTIFICATE';
                certDesc =
                    'is officially certified to operate doctor chambers, manage digital OPD appointments, and conduct clinical pathology laboratory test diagnostics under Doctorwala.';
              } else if (isOPD && isDoctor) {
                certTitle = 'CLINICAL CONSULTATION CERTIFICATE';
                certDesc =
                    'is officially certified to manage patient consulting chambers, digital OPD services, and professional healthcare practice under Doctorwala.';
              } else if (isDoctor && isPathology) {
                certTitle = 'PRACTITIONER & DIAGNOSTIC CERTIFICATE';
                certDesc =
                    'is officially certified to manage independent clinical consultations, pathology diagnostics, and patient lab test services under Doctorwala.';
              } else if (isOPD) {
                certTitle = 'OPD CHAMBER CERTIFICATE';
                certDesc =
                    'is officially certified as a registered OPD Clinic Partner, authorized to run doctor chambers, schedule patient appointments, and provide digital health consultations under Doctorwala.';
              } else if (isPathology) {
                certTitle = 'PATHOLOGY LABORATORY CERTIFICATE';
                certDesc =
                    'is officially certified as a clinical Pathology Lab Partner, authorized to manage lab tests, analyze diagnostics, and generate patient pathology reports under Doctorwala.';
              } else if (isDoctor) {
                certTitle = 'MEDICAL PRACTITIONER CERTIFICATE';
                certDesc =
                    'is officially certified as a registered Medical Practitioner, authorized to manage independent clinical chambers, schedule patient consultations, and offer digital care under Doctorwala.';
              }

              return FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Stack(
                  children: [
                    // Background Certificate Container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFCFBF7,
                        ), // Warm premium ivory/parchment background
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(
                            0xFFD4AF37,
                          ), // Metallic Gold outer border
                          width: 3.0,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.teal.withValues(
                              alpha: 0.35,
                            ), // Inner teal border
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          children: [
                            // Medical Watermark Icon in background
                            Positioned(
                              right: -10,
                              bottom: 10,
                              child: Icon(
                                Icons.local_hospital_rounded,
                                size: 130,
                                color: AppColors.teal.withValues(alpha: 0.025),
                              ),
                            ),
                            Positioned(
                              left: -10,
                              top: 20,
                              child: Icon(
                                Icons.healing_rounded,
                                size: 60,
                                color: AppColors.teal.withValues(alpha: 0.02),
                              ),
                            ),

                            // Content Column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Top Logo & Stamp
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'assets/images/logo.png',
                                      height: 28,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.local_hospital_rounded,
                                                color: AppColors.teal,
                                                size: 28,
                                              ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFD4AF37,
                                        ).withValues(alpha: 0.1),
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37),
                                          width: 1.0,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'OFFICIAL MEMBER',
                                        style: GoogleFonts.manrope(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF8B7355),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Certificate Title
                                Text(
                                  certTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.navy,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This is proudly presented to',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.navy.withValues(
                                      alpha: 0.65,
                                    ),
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
                                    color: AppColors.teal,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Classic Star Divider
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 35,
                                      height: 1,
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.6),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFD4AF37),
                                        size: 10,
                                      ),
                                    ),
                                    Container(
                                      width: 35,
                                      height: 1,
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Partnership Text
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    certDesc,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PARTNER ID',
                                              style: GoogleFonts.manrope(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textSecondary
                                                    .withValues(alpha: 0.6),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.partnerData['partner_id'] ??
                                                  'N/A',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Official Award Seal/Stamp Image with Gold Circular Shadow
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFD4AF37,
                                              ).withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/images/award.png',
                                          height: 42,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => const Icon(
                                                Icons.workspace_premium_rounded,
                                                color: Color(0xFFD4AF37),
                                                size: 36,
                                              ),
                                        ),
                                      ),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'REPRESENTATIVE',
                                              style: GoogleFonts.manrope(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textSecondary
                                                    .withValues(alpha: 0.6),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 30),
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
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delayMs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!, width: 1.5),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.manrope(
                    fontSize: 26,
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
    );
  }

  // TAB 1: PENDING APPOINTMENTS
  Widget _buildPendingAppointmentsTab() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pending_actions_rounded,
                color: Colors.orangeAccent,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pending Appointments',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending appointments found.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GENERIC PLACEHOLDER TAB
  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.teal, size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This section is coming soon.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: PROFILE DETAILS
  Widget _buildProfileTab() {
    final partnerId = widget.partnerData['partner_id'] ?? 'N/A';
    final email = widget.partnerData['partner_email'] ?? 'N/A';
    final mobile = widget.partnerData['partner_mobile_number'] ?? 'N/A';
    final status = widget.partnerData['status'] ?? 'N/A';
    final regType =
        widget.partnerData['registration_type']?.toString() ?? 'N/A';

    final state = widget.partnerData['partner_state'] ?? 'N/A';
    final city = widget.partnerData['partner_city'] ?? 'N/A';
    final pincode = widget.partnerData['partner_pincode'] ?? 'N/A';
    final landmark = widget.partnerData['partner_landmark'] ?? 'N/A';
    final address = widget.partnerData['partner_address'] ?? 'N/A';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: FadeInUp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[100]!, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Details',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Partner ID', partnerId),
                  _buildDetailRow('Email Address', email),
                  _buildDetailRow('Mobile Number', mobile),
                  _buildDetailRow('Account Status', status),
                  _buildDetailRow('Category Type', regType),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Address Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[100]!, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address Information',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('State', state),
                  _buildDetailRow('City', city),
                  _buildDetailRow('Pincode', pincode),
                  _buildDetailRow('Landmark', landmark),
                  _buildDetailRow('Street Address', address),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
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
