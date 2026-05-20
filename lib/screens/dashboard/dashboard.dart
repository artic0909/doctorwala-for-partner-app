import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/session_manager.dart';
import '../login_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/sidebar.dart';

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
                  ? 'Appointments'
                  : 'Partner Profile',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await SessionManager.clearSession();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
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
        return _buildAppointmentsTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // TAB 0: HOME / COUNTING CARDS
  Widget _buildHomeTab() {
    final clinicName = widget.partnerData['partner_clinic_name'] ?? 'N/A';
    final contactPerson = widget.partnerData['partner_contact_person_name'] ?? 'N/A';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Welcome banner
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.getStartedGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinicName,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        contactPerson,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
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
            children: [
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
              _buildCountCard(
                title: 'Total Doctors',
                count: '0',
                icon: Icons.people_alt_rounded,
                color: AppColors.navy,
                delayMs: 600,
              ),
              _buildCountCard(
                title: 'Pathology Tests',
                count: '0',
                icon: Icons.biotech_rounded,
                color: Colors.purpleAccent,
                delayMs: 700,
                isFullWidth: true, // GridView.count doesn't support colSpan easily, we can add separately below if needed
              ),
            ],
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
    bool isFullWidth = false,
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
          border: Border.all(
            color: Colors.grey[100]!,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
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

  // TAB 1: APPOINTMENTS
  Widget _buildAppointmentsTab() {
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
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.teal,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Appointments Management',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No appointments found for today.',
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
    final regType = widget.partnerData['registration_type']?.toString() ?? 'N/A';

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
}
