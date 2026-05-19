import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../login_screen.dart';
import '../../core/session_manager.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> partnerData;

  const DashboardScreen({super.key, required this.partnerData});

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.teal, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicName = partnerData['partner_clinic_name'] ?? 'Partner Clinic';
    final contactPerson = partnerData['partner_contact_person_name'] ?? 'Contact Person';
    final partnerId = partnerData['partner_id'] ?? 'N/A';
    final email = partnerData['partner_email'] ?? 'N/A';
    final mobile = partnerData['partner_mobile_number'] ?? 'N/A';
    final status = partnerData['status'] ?? 'Pending';
    
    // Address fields
    final state = partnerData['partner_state'] ?? '';
    final city = partnerData['partner_city'] ?? '';
    final pincode = partnerData['partner_pincode'] ?? '';
    final landmark = partnerData['partner_landmark'] ?? '';
    final address = partnerData['partner_address'] ?? '';

    // Registration Type formatting
    String regTypeStr = '';
    if (partnerData['registration_type'] != null) {
      if (partnerData['registration_type'] is List) {
        regTypeStr = (partnerData['registration_type'] as List).join(' & ');
      } else {
        regTypeStr = partnerData['registration_type'].toString();
      }
    }

    final isPending = status.toString().toLowerCase() == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Partner Hub',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.navy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              // Clear persistent session locally
              await SessionManager.clearSession();
              if (!context.mounted) return;
              
              // Redirect to LoginScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            color: Colors.grey[100],
            height: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. WELCOME CARD
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.navy,
                        AppColors.navy.withBlue(110),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPending 
                                  ? Colors.orangeAccent.withValues(alpha: 0.18) 
                                  : AppColors.teal.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isPending ? Colors.orangeAccent : AppColors.teal,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isPending ? Colors.orangeAccent : AppColors.teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.manrope(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: isPending ? Colors.orangeAccent : AppColors.teal,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            partnerId,
                            style: GoogleFonts.manrope(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        clinicName,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        regTypeStr.toUpperCase(),
                        style: GoogleFonts.manrope(
                          color: AppColors.teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. STATISTICS GRID
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  children: [
                    _buildStatCard(
                      title: 'Total Appointments',
                      value: '124',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.teal,
                    ),
                    _buildStatCard(
                      title: 'Active Patients',
                      value: '48',
                      icon: Icons.people_outline_rounded,
                      color: Colors.indigoAccent,
                    ),
                    _buildStatCard(
                      title: 'Pending Lab Tests',
                      value: '18',
                      icon: Icons.science_outlined,
                      color: Colors.purpleAccent,
                    ),
                    _buildStatCard(
                      title: 'Revenue Generated',
                      value: '₹14.8K',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. PROFILE DETAILS SECTION CARD
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[100]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.01),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, color: AppColors.teal, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'PARTNER REGISTRATION DETAILS',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.navy,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildDetailRow(Icons.face_rounded, 'Contact Person', contactPerson),
                            _buildDetailRow(Icons.alternate_email_rounded, 'Registered Email', email),
                            _buildDetailRow(Icons.phone_android_rounded, 'Mobile Number', mobile),
                            _buildDetailRow(Icons.map_rounded, 'Location state', state),
                            _buildDetailRow(Icons.location_city_rounded, 'City / Township', city),
                            _buildDetailRow(Icons.pin_drop_rounded, 'Postal Pin Code', pincode),
                            _buildDetailRow(Icons.assistant_navigation, 'Landmark Reference', landmark),
                            _buildDetailRow(Icons.home_work_outlined, 'Full Operating Address', address),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
