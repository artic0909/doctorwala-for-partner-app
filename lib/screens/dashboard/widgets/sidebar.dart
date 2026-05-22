import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import '../../../core/session_manager.dart';
import '../../login_screen.dart';

class CustomSidebar extends StatelessWidget {
  final Map<String, dynamic> partnerData;
  final int currentIndex;
  final Function(int) onTap;

  const CustomSidebar({
    super.key,
    required this.partnerData,
    required this.currentIndex,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final rawRegType = partnerData['registration_type'];

    final types = _parseRegistrationTypes(rawRegType);
    final hasOPD = types.contains('OPD');
    final hasPathology = types.contains('Pathology');
    final hasDoctor = types.contains('Doctor');

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.getStartedGradient,
            ),
            child: Stack(
              children: [
                // Faded logo covering the background of the top portion
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.4, 0.95],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white24,
                          size: 70,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 25,
                    bottom: 25,
                    left: 20,
                    right: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PARTNER ID',
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  color: AppColors.teal,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  partnerData['partner_id'] ?? 'N/A',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.navy,
                                    letterSpacing: 0.8,
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
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  context: context,
                ),
                const Divider(),

                // Clinic Profiles Group
                if (hasOPD || hasPathology) ...[
                  _buildSectionHeader('Clinic Profiles'),
                  if (hasOPD)
                    _buildDrawerItem(
                      icon: Icons.local_hospital_rounded,
                      label: 'Add Doctor chamber',
                      index: 3,
                      context: context,
                    ),
                  if (hasPathology)
                    _buildDrawerItem(
                      icon: Icons.medical_services_rounded,
                      label: 'Add Pathology clinic',
                      index: 4,
                      context: context,
                    ),
                ],

                // Listings Group
                _buildSectionHeader('Listings'),
                if (hasDoctor)
                  _buildDrawerItem(
                    icon: Icons.assignment_ind_rounded,
                    label: 'List myself',
                    index: 11,
                    context: context,
                  ),
                if (hasOPD)
                  _buildDrawerItem(
                    icon: Icons.person_add_rounded,
                    label: 'Add Doctors',
                    index: 5,
                    context: context,
                  ),
                if (hasPathology)
                  _buildDrawerItem(
                    icon: Icons.science_rounded,
                    label: 'Add Tests',
                    index: 6,
                    context: context,
                  ),

                // Medical Card Access Group
                _buildSectionHeader('Medical Card Access'),
                _buildDrawerItem(
                  icon: Icons.badge_rounded,
                  label: 'Medical Card Access',
                  index: 7,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_rounded,
                  label: 'Patient Lists',
                  index: 8,
                  context: context,
                ),

                // Appointments Group
                _buildSectionHeader('Appointments'),
                _buildDrawerItem(
                  icon: Icons.pending_actions_rounded,
                  label: 'Upcoming Appointments',
                  index: 1,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.task_alt_rounded,
                  label: 'Complete Appointments',
                  index: 9,
                  context: context,
                ),

                _buildDrawerItem(
                  icon: Icons.cancel_rounded,
                  label: 'Cancelled Appointments',
                  index: 14,
                  context: context,
                ),

                // Settings Group
                _buildSectionHeader('Settings'),
                _buildDrawerItem(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Account Settings',
                  index: 2,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help?',
                  index: 10,
                  context: context,
                ),

                const Divider(height: 32),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () async {
                    // Close drawer
                    Navigator.pop(context);
                    // Logout
                    await SessionManager.clearSession();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final isSelected = currentIndex == index;

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color:
            isSelected ? AppColors.teal : AppColors.navy.withValues(alpha: 0.7),
        size: 20,
      ),
      title: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
          color: isSelected ? AppColors.teal : AppColors.navy,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.teal.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        // Close drawer first
        Navigator.pop(context);
        onTap(index);
      },
    );
  }
}
