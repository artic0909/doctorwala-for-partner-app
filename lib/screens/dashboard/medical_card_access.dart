import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class _Theme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Turquoise/Teal
  static const Color accentLight = Color(0xFFF0FDFA); // Soft Mint/Turquoise Light
  static const Color bgTint = Color(0xFFF8FAFC); // Slate background
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium slate
  static const Color border = Color(0xFFE2E8F0); // Border color
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class MedicalCardAccessTab extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  final VoidCallback? onRequestSent;

  const MedicalCardAccessTab({
    super.key,
    required this.partnerData,
    this.onRequestSent,
  });

  @override
  State<MedicalCardAccessTab> createState() => _MedicalCardAccessTabState();
}

class _MedicalCardAccessTabState extends State<MedicalCardAccessTab> {
  final _formKey = GlobalKey<FormState>();
  final _medicalCardController = TextEditingController();
  final _memberIdController = TextEditingController();

  bool _isLoadingMeta = true;
  bool _isLookingUp = false;
  bool _isSendingRequest = false;

  List<dynamic> _doctors = [];
  Map<String, dynamic>? _foundPatient;
  int? _selectedDoctorId;

  @override
  void initState() {
    super.initState();
    _fetchMeta();
  }

  @override
  void dispose() {
    _medicalCardController.dispose();
    _memberIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchMeta() async {
    setState(() => _isLoadingMeta = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final res = await ApiService.getMedicalCardAccessMeta(token: token);
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _doctors = res['data']['doctors'] ?? [];
          if (_doctors.length == 1) {
            _selectedDoctorId = _doctors[0]['id'] as int?;
          }
        });
      }
    } catch (_) {
      // Fail silently or show error
    } finally {
      setState(() => _isLoadingMeta = false);
    }
  }

  Future<void> _lookupPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLookingUp = true;
      _foundPatient = null;
      _selectedDoctorId = _doctors.length == 1 ? _doctors[0]['id'] as int? : null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final res = await ApiService.lookupPatient(
        medicalId: _medicalCardController.text.trim(),
        memberId: _memberIdController.text.trim(),
        token: token,
      );

      if (res['success'] == true && res['found'] == true) {
        setState(() {
          _foundPatient = res['patient'];
        });
        if (mounted) {
          CustomAlerts.showSuccess(context, 'Patient found successfully!');
        }
      } else {
        if (mounted) {
          CustomAlerts.showError(
            context,
            res['message'] ?? 'No patient found with provided credentials.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomAlerts.showError(context, 'An unexpected error occurred.');
      }
    } finally {
      setState(() => _isLookingUp = false);
    }
  }

  Future<void> _sendAccessRequest() async {
    if (_foundPatient == null || _selectedDoctorId == null) {
      CustomAlerts.showError(context, 'Please select a doctor to proceed.');
      return;
    }

    setState(() => _isSendingRequest = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final res = await ApiService.sendMedicalCardAccessRequest(
        dwUserId: _foundPatient!['id'],
        doctorId: _selectedDoctorId!,
        medicalId: _medicalCardController.text.trim(),
        memberId: _memberIdController.text.trim(),
        token: token,
      );

      if (res['success'] == true) {
        if (mounted) {
          CustomAlerts.showSuccess(
            context,
            res['message'] ?? 'Access request sent successfully!',
          );
        }
        setState(() {
          _foundPatient = null;
          _selectedDoctorId = _doctors.length == 1 ? _doctors[0]['id'] as int? : null;
          _medicalCardController.clear();
          _memberIdController.clear();
        });
        if (widget.onRequestSent != null) {
          widget.onRequestSent!();
        }
      } else {
        if (mounted) {
          CustomAlerts.showError(
            context,
            res['message'] ?? 'Failed to send request.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        CustomAlerts.showError(context, 'An unexpected error occurred.');
      }
    } finally {
      setState(() => _isSendingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Theme.bgTint,
      body: _isLoadingMeta
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_Theme.accent),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner card
                  FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E3A8A), // Navy Blue
                            Color(0xFF0F172A), // Slate Dark
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _Theme.accent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.badge_rounded,
                                  color: _Theme.accent,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SECURE MEDICAL ID ACCESS',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _Theme.accent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Request Medical Card Access',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter patient\'s Medical Card Number and Member ID to check their digital health record, vitals, prescriptions, and past medical history.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lookup Form Card
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _Theme.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _Theme.primary.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Lookup Details',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _Theme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Medical Card Input
                            Text(
                              'MEDICAL CARD NUMBER',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _Theme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _medicalCardController,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _Theme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. DW26 7211 03',
                                hintStyle: GoogleFonts.manrope(color: Colors.grey.shade400, fontSize: 13),
                                prefixIcon: const Icon(Icons.credit_card_rounded, color: _Theme.accent, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _Theme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _Theme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _Theme.accent, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Medical Card Number is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Member ID Input
                            Text(
                              'MEMBER ID',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _Theme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _memberIdController,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _Theme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. 01',
                                hintStyle: GoogleFonts.manrope(color: Colors.grey.shade400, fontSize: 13),
                                prefixIcon: const Icon(Icons.person_pin_rounded, color: _Theme.accent, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _Theme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _Theme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _Theme.accent, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Member ID is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Search Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: _Theme.buttonGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLookingUp ? null : _lookupPatient,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLookingUp
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Lookup Patient',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Found Patient Display Card
                  if (_foundPatient != null) ...[
                    const SizedBox(height: 20),
                    FadeInUp(
                      duration: const Duration(milliseconds: 350),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _Theme.accentLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _Theme.accent.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _Theme.accent.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_user_rounded, color: _Theme.accent, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _foundPatient!['user_name'] ?? 'N/A',
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _Theme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Card No: ${_foundPatient!['medical_card_no'] ?? 'N/A'}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _Theme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: _Theme.border),
                            const SizedBox(height: 12),

                            // Select Doctor Form
                            Text(
                              'SELECT CONSULTING DOCTOR',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _Theme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _Theme.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedDoctorId,
                                  hint: Text(
                                    'Select a doctor...',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  isExpanded: true,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: _Theme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: _doctors.map<DropdownMenuItem<int>>((doc) {
                                    return DropdownMenuItem<int>(
                                      value: doc['id'] as int,
                                      child: Text(doc['doctor_name'] ?? 'N/A'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedDoctorId = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Send Request Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _isSendingRequest || _selectedDoctorId == null
                                    ? null
                                    : _sendAccessRequest,
                                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                label: Text(
                                  'Send Access Request',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _Theme.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
