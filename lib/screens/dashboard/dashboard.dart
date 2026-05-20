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
        return _buildPlaceholderTab('Add Doctors', Icons.person_add_rounded);
      case 6:
        return _buildPlaceholderTab('Add Test', Icons.science_rounded);
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
                    
                    // Signature / Footer Row
                    Container(
                      padding: const EdgeInsets.only(top: 12),
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
                          Column(
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
                          Column(
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
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Overview Header
          FadeIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Practice Overview',
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
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: cards,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
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
