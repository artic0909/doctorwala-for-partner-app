import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_colors.dart';

class OnboardingTutorialDialog extends StatefulWidget {
  final VoidCallback onStartSetup;
  final bool autoTriggered;
  final Map<String, dynamic>? partnerData;

  const OnboardingTutorialDialog({
    super.key,
    required this.onStartSetup,
    this.autoTriggered = false,
    this.partnerData,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onStartSetup,
    bool autoTriggered = false,
    Map<String, dynamic>? partnerData,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OnboardingTutorialDialog(
        onStartSetup: onStartSetup,
        autoTriggered: autoTriggered,
        partnerData: partnerData,
      ),
    );
  }

  @override
  State<OnboardingTutorialDialog> createState() =>
      _OnboardingTutorialDialogState();
}

class _OnboardingTutorialDialogState extends State<OnboardingTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;
  late final List<Map<String, dynamic>> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _buildTypeSpecificSteps();
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

  List<Map<String, dynamic>> _buildTypeSpecificSteps() {
    final rawRegType = widget.partnerData?['registration_type'];
    final types = _parseRegistrationTypes(rawRegType);
    final hasOPD = types.contains('OPD');
    final hasPathology = types.contains('Pathology');

    if (hasOPD && hasPathology) {
      return [
        {
          'step': 1,
          'badge': 'STEP 1 OF 4',
          'title': 'OPD Chamber Setup',
          'subtitle': 'Clinic Name & Registration',
          'icon': Icons.local_hospital_rounded,
          'iconColor': const Color(0xFF0D9488),
          'bgColor': const Color(0xFFCCFBF1),
          'shortText':
              'Complete your clinic contact details, GSTIN, and registration type under Doctor Chamber.',
          'actionLabel': 'Setup OPD Chamber ➔',
          'tag': 'Clinic Practice Setup',
        },
        {
          'step': 2,
          'badge': 'STEP 2 OF 4',
          'title': 'Pathology Lab Profile',
          'subtitle': 'Diagnostic Center & Address',
          'icon': Icons.biotech_rounded,
          'iconColor': const Color(0xFF9333EA),
          'bgColor': const Color(0xFFF3E8FF),
          'shortText':
              'Fill in your laboratory contact details, registration type, and accurate diagnostic center location.',
          'actionLabel': 'Setup Pathology Lab ➔',
          'tag': 'Diagnostic Center Setup',
        },
        {
          'step': 3,
          'badge': 'STEP 3 OF 4',
          'title': 'Add Doctors & Tests',
          'subtitle': 'Specialists & Test Catalog',
          'icon': Icons.groups_rounded,
          'iconColor': const Color(0xFF2563EB),
          'bgColor': const Color(0xFFDBEAFE),
          'shortText':
              'Add visiting specialist doctors with days & fees to OPD, and medical tests with rates to Pathology.',
          'actionLabel': 'Add Doctors & Tests ➔',
          'tag': 'Active Services',
        },
        {
          'step': 4,
          'badge': 'STEP 4 OF 4',
          'title': '100% Unlock All Features',
          'subtitle': 'Appointments, Lab & Medical Cards',
          'icon': Icons.verified_rounded,
          'iconColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFDCFCE7),
          'shortText':
              'Completing both setups automatically unlocks OPD Appointments, Pathology Bookings, and Patient Medical Cards!',
          'actionLabel': 'Start Combined Setup 🚀',
          'tag': 'Full Portal Unlock',
        },
      ];
    } else if (hasOPD) {
      return [
        {
          'step': 1,
          'badge': 'STEP 1 OF 4',
          'title': 'OPD Chamber Details',
          'subtitle': 'Clinic Name & Contact Person',
          'icon': Icons.local_hospital_rounded,
          'iconColor': const Color(0xFF0D9488),
          'bgColor': const Color(0xFFCCFBF1),
          'shortText':
              'Fill in your clinic name, contact person name, mobile number, and clinic registration type under Doctor Chamber.',
          'actionLabel': 'Open Doctor Chamber ➔',
          'tag': 'Official Clinic Listing',
        },
        {
          'step': 2,
          'badge': 'STEP 2 OF 4',
          'title': 'Chamber Location & Address',
          'subtitle': 'State, City, Pin & Map Link',
          'icon': Icons.location_on_rounded,
          'iconColor': const Color(0xFF0284C7),
          'bgColor': const Color(0xFFE0F2FE),
          'shortText':
              'Provide full clinic address, city, pincode, landmark, and optional Google Map link for seamless patient visits.',
          'actionLabel': 'Set Clinic Address ➔',
          'tag': 'Patient Navigation',
        },
        {
          'step': 3,
          'badge': 'STEP 3 OF 4',
          'title': 'Add Chamber Doctors',
          'subtitle': 'Visiting Specialists & Timetable',
          'icon': Icons.person_add_rounded,
          'iconColor': const Color(0xFF2563EB),
          'bgColor': const Color(0xFFDBEAFE),
          'shortText':
              'Add the visiting doctors practicing in your clinic along with their degrees, visiting days, timings, and fees.',
          'actionLabel': 'Add Chamber Doctors ➔',
          'tag': 'Doctor Directory',
        },
        {
          'step': 4,
          'badge': 'STEP 4 OF 4',
          'title': '100% Unlock OPD Portal',
          'subtitle': 'Bookings, Patient Lists & Cards',
          'icon': Icons.verified_rounded,
          'iconColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFDCFCE7),
          'shortText':
              'Saving your OPD details and adding doctors reaches 100% to unlock OPD Appointments, Patient Records, and Cards!',
          'actionLabel': 'Start OPD Setup 🚀',
          'tag': 'Instant Portal Unlock',
        },
      ];
    } else if (hasPathology) {
      return [
        {
          'step': 1,
          'badge': 'STEP 1 OF 4',
          'title': 'Pathology Lab Profile',
          'subtitle': 'Diagnostic Center & Reg Type',
          'icon': Icons.biotech_rounded,
          'iconColor': const Color(0xFF9333EA),
          'bgColor': const Color(0xFFF3E8FF),
          'shortText':
              'Enter your diagnostic center name, registration type, contact person, and mobile number under Pathology Clinic.',
          'actionLabel': 'Open Pathology Clinic ➔',
          'tag': 'Diagnostic Center Listing',
        },
        {
          'step': 2,
          'badge': 'STEP 2 OF 4',
          'title': 'Laboratory Address & Location',
          'subtitle': 'State, City, Pin & Landmark',
          'icon': Icons.location_on_rounded,
          'iconColor': const Color(0xFF0284C7),
          'bgColor': const Color(0xFFE0F2FE),
          'shortText':
              'Provide accurate laboratory location details, city, pincode, and landmark for patient sample collection.',
          'actionLabel': 'Set Lab Address ➔',
          'tag': 'Center Navigation',
        },
        {
          'step': 3,
          'badge': 'STEP 3 OF 4',
          'title': 'Add Diagnostic Tests',
          'subtitle': 'Test Catalog, Samples & Prices',
          'icon': Icons.science_rounded,
          'iconColor': const Color(0xFFEA580C),
          'bgColor': const Color(0xFFFFEDD5),
          'shortText':
              'Add the pathology and diagnostic tests offered at your center with transparent test fees and duration.',
          'actionLabel': 'Add Medical Tests ➔',
          'tag': 'Test Catalog',
        },
        {
          'step': 4,
          'badge': 'STEP 4 OF 4',
          'title': '100% Unlock Lab Portal',
          'subtitle': 'Online Test Bookings & Reports',
          'icon': Icons.verified_rounded,
          'iconColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFDCFCE7),
          'shortText':
              'Saving pathology details and adding tests reaches 100% to unlock test bookings, digital report management, and cards!',
          'actionLabel': 'Start Lab Setup 🚀',
          'tag': 'Instant Portal Unlock',
        },
      ];
    } else {
      // Default: Doctor Setup
      return [
        {
          'step': 1,
          'badge': 'STEP 1 OF 4',
          'title': 'Doctor Profile & Specialty',
          'subtitle': 'Name, Degree & Specialty',
          'icon': Icons.badge_rounded,
          'iconColor': const Color(0xFF4F46E5),
          'bgColor': const Color(0xFFEEF2FF),
          'shortText':
              'Enter your official name, medical degree (e.g. MBBS, MD) and specialization so patients find you in search.',
          'actionLabel': 'Open Doctor Details ➔',
          'tag': 'Official practice listing',
        },
        {
          'step': 2,
          'badge': 'STEP 2 OF 4',
          'title': 'Set Consultation Fees',
          'subtitle': 'OPD Patient Charges',
          'icon': Icons.payments_rounded,
          'iconColor': const Color(0xFF0284C7),
          'bgColor': const Color(0xFFE0F2FE),
          'shortText':
              'Set your consultation fee in ₹ (INR). Patients will see this transparent fee when booking appointments.',
          'actionLabel': 'Set Consultation Fees ➔',
          'tag': 'Transparent booking fees',
        },
        {
          'step': 3,
          'badge': 'STEP 3 OF 4',
          'title': 'Weekly Visiting Schedule',
          'subtitle': 'Chamber Days & Timetable',
          'icon': Icons.calendar_month_rounded,
          'iconColor': const Color(0xFF0D9488),
          'bgColor': const Color(0xFFCCFBF1),
          'shortText':
              'Select your available weekdays (e.g. Mon, Wed, Fri) with consulting start and end time slots.',
          'actionLabel': 'Configure Timetable ➔',
          'tag': 'Automated appointment slots',
        },
        {
          'step': 4,
          'badge': 'STEP 4 OF 4',
          'title': '100% Unlock All Features',
          'subtitle': 'Appointments, Patients & Cards',
          'icon': Icons.verified_rounded,
          'iconColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFDCFCE7),
          'shortText':
              'Hit "Save Details". Reaching 100% automatically unlocks Appointments, Patient Records and Medical Cards!',
          'actionLabel': 'Start Profile Setup 🚀',
          'tag': 'Instant portal unlock',
        },
      ];
    }
  }

  Future<void> _handleClose() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dismiss_onboarding_tutorial_v1', true);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dismiss_onboarding_tutorial_v1', true);
    if (mounted) {
      Navigator.of(context).pop();
      widget.onStartSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TOP DRAG HANDLE
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // HEADER ROW: TITLE, STEP PILL & CLOSE (✖)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Partner Setup Guide',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_currentPage + 1}/4',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleClose,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // SHORT COMPACT STEP CARDS (PAGE VIEW)
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon & Title Row
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: step['bgColor'] as Color,
                              ),
                              child: Icon(
                                step['icon'] as IconData,
                                size: 24,
                                color: step['iconColor'] as Color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title'] as String,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step['subtitle'] as String,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: step['iconColor'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Relatable Short Description
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            step['shortText'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Relatable Tag
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: step['iconColor'] as Color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              step['tag'] as String,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: step['iconColor'] as Color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // DIRECT REDIRECT BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _handleRedirect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: step['iconColor'] as Color,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  step['actionLabel'] as String,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
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
            ),

            const SizedBox(height: 6),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // BOTTOM CONTROLS & STEP DOTS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PAGE INDICATOR DOTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 18 : 6,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.teal
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  // PREV & NEXT CONTROLS
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: Text(
                            'Previous',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (_currentPage < _steps.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _handleRedirect();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            side: const BorderSide(color: AppColors.teal, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            _currentPage == _steps.length - 1
                                ? 'Finish & Start ➔'
                                : 'Next Step ➔',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // FOOTER ROW: CHECKBOX & GOT IT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _dontShowAgain = !_dontShowAgain;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: _dontShowAgain,
                                activeColor: AppColors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _dontShowAgain = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Don't auto-show",
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _handleClose,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Got It (Close)',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
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
      ),
    );
  }
}
