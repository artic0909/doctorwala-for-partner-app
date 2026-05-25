import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class _Theme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Turquoise/Teal
  static const Color accentLight = Color(0xFFF0FDFA); // Soft Mint/Turquoise Light
  static const Color bgTint = Color(0xFFF8FAFC); // Slate background
  static const Color textSecondary = Color(0xFF64748B); // Medium slate
  static const Color border = Color(0xFFE2E8F0); // Border color
}

class PatientMedicalHistoryScreen extends StatefulWidget {
  final String encryptedId;
  final Map<String, dynamic> partnerData;

  const PatientMedicalHistoryScreen({
    super.key,
    required this.encryptedId,
    required this.partnerData,
  });

  @override
  State<PatientMedicalHistoryScreen> createState() => _PatientMedicalHistoryScreenState();
}

class _PatientMedicalHistoryScreenState extends State<PatientMedicalHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _historyData;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token missing.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.getPatientMedicalHistory(
        encryptedId: widget.encryptedId,
        token: token,
      );

      if (response['success'] == true) {
        setState(() {
          _historyData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to retrieve medical history.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _openAttachment(String path) async {
    final String fullUrl = 'https://www.doctorwala.info/storage/$path';
    final isPdf = path.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      final Uri uri = Uri.parse(fullUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          CustomAlerts.showError(context, 'Could not open PDF file.');
        }
      }
    } else {
      // Show full screen image viewer dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: const Text('Failed to load image.'),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _Theme.bgTint,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_Theme.accent),
          ),
        ),
      );
    }

    if (_errorMessage != null || _historyData == null) {
      return Scaffold(
        backgroundColor: _Theme.bgTint,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _Theme.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildErrorState(),
      );
    }

    final data = _historyData!;
    final patient = data['patient'] ?? {};
    final histories = data['histories'] as List? ?? [];
    final systemPrescriptions = data['systemPrescriptions'] as List? ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _Theme.bgTint,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _Theme.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical History',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w900,
                  color: _Theme.primary,
                  fontSize: 17,
                ),
              ),
              Text(
                patient['user_name'] ?? 'N/A',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: _Theme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: _Theme.accent,
            unselectedLabelColor: _Theme.textSecondary,
            indicatorColor: _Theme.accent,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: 'UPLOADED FILES'),
              Tab(text: 'SYSTEM PRESCRIPTIONS'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Tab 1: Uploaded Medical Files
            RefreshIndicator(
              onRefresh: _fetchHistory,
              color: _Theme.accent,
              child: histories.isEmpty
                  ? _buildEmptyState('No Uploaded Files', 'There are no external reports or prescription files uploaded for this patient.')
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                      itemCount: histories.length,
                      itemBuilder: (context, index) {
                        final record = histories[index] as Map<String, dynamic>;
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: _buildHistoryRecordCard(record),
                        );
                      },
                    ),
            ),

            // Tab 2: System Prescriptions
            RefreshIndicator(
              onRefresh: _fetchHistory,
              color: _Theme.accent,
              child: systemPrescriptions.isEmpty
                  ? _buildEmptyState('No Prescriptions', 'There are no system-generated digital prescriptions found in history.')
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                      itemCount: systemPrescriptions.length,
                      itemBuilder: (context, index) {
                        final pres = systemPrescriptions[index] as Map<String, dynamic>;
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: _buildSystemPrescriptionCard(pres),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String desc) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: _Theme.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _Theme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _Theme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRecordCard(Map<String, dynamic> record) {
    final heading = record['heading'] ?? 'N/A';
    final date = record['date_of_report'] != null
        ? record['date_of_report'].toString().split('T')[0]
        : 'N/A';
    final type = record['type'] ?? 'report';
    final clinicName = record['clinic_name'] ?? record['opd']?['partner_clinic_name'] ?? 'N/A';
    final doctorName = record['doctor_name'] ?? record['doctor']?['doctor_name'] ?? 'N/A';
    final List<dynamic> images = record['images'] as List? ?? [];

    final isReport = type == 'report';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Theme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _Theme.primary.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Type tag & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isReport ? Colors.blueAccent : Colors.purpleAccent).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isReport ? Colors.blueAccent : Colors.purple,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 12, color: _Theme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _Theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Heading
          Text(
            heading,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _Theme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Meta Information
          if (doctorName != 'N/A')
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_rounded, size: 13, color: _Theme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Doctor: $doctorName',
                      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: _Theme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              const Icon(Icons.local_hospital_outlined, size: 13, color: _Theme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Clinic: $clinicName',
                  style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: _Theme.textSecondary),
                ),
              ),
            ],
          ),

          // Attachments
          if (images.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Text(
              'ATTACHED FILES (${images.length})',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: _Theme.textSecondary.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images.asMap().entries.map<Widget>((entry) {
                final int index = entry.key;
                final String path = entry.value.toString();
                final isPdf = path.toLowerCase().endsWith('.pdf');
                final String displayName = 'Attachment ${index + 1}';
                return InkWell(
                  onTap: () => _openAttachment(path),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPdf ? const Color(0xFFFFF5F5) : _Theme.accentLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPdf ? Colors.red.withValues(alpha: 0.2) : _Theme.accent.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                          color: isPdf ? Colors.redAccent : _Theme.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPdf ? Colors.red.shade800 : _Theme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemPrescriptionCard(Map<String, dynamic> pres) {
    final date = pres['prescription_date'] != null
        ? pres['prescription_date'].toString().split('T')[0]
        : 'N/A';
    final doctorName = pres['doctor_name'] ?? pres['doctor']?['doctor_name'] ?? 'N/A';
    final clinicName = pres['opd']?['partner_clinic_name'] ?? 'N/A';

    final symptomsRaw = pres['symptoms'];
    final testsRaw = pres['recommended_tests'];
    final medicinesRaw = pres['medicines'];

    List<String> symptoms = [];
    if (symptomsRaw is List) {
      symptoms = symptomsRaw.map((e) => e.toString()).toList();
    } else if (symptomsRaw is String) {
      symptoms = [symptomsRaw];
    }

    List<String> tests = [];
    if (testsRaw is List) {
      tests = testsRaw.map((e) => e.toString()).toList();
    } else if (testsRaw is String) {
      tests = [testsRaw];
    }

    List<dynamic> medicines = [];
    if (medicinesRaw is List) {
      medicines = medicinesRaw;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Theme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _Theme.primary.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _Theme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PRESCRIPTION',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _Theme.accent,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _Theme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Prescribed by $doctorName',
                style: GoogleFonts.manrope(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: _Theme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Clinic: $clinicName',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _Theme.textSecondary,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Symptoms
            if (symptoms.isNotEmpty) ...[
              _buildDetailSectionTitle('Symptoms / Complaints'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: symptoms.map((sym) => Chip(
                  label: Text(sym, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: _Theme.primary)),
                  backgroundColor: _Theme.bgTint,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Medicines
            if (medicines.isNotEmpty) ...[
              _buildDetailSectionTitle('Medicines / Rx'),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: medicines.length,
                itemBuilder: (context, idx) {
                  final med = medicines[idx];
                  final mName = med['name'] ?? med['medicine_name'] ?? 'N/A';
                  final mDosage = med['dosage'] ?? 'N/A';
                  final mTiming = med['timing'] ?? 'N/A';
                  final mDuration = med['duration'] ?? 'N/A';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: _Theme.accent)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: '$mName ',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _Theme.primary,
                              ),
                              children: [
                                TextSpan(
                                  text: '($mDosage) — $mTiming, for $mDuration',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _Theme.textSecondary,
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
              const SizedBox(height: 14),
            ],

            // Recommended Tests
            if (tests.isNotEmpty) ...[
              _buildDetailSectionTitle('Recommended Tests'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tests.map((t) => Chip(
                  label: Text(t, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade900)),
                  backgroundColor: const Color(0xFFFAF5FF),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Vitals snapshot
            if (pres['bp'] != null || pres['pulse'] != null || pres['temperature'] != null) ...[
              _buildDetailSectionTitle('Vitals at Visit'),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (pres['bp'] != null)
                    Expanded(child: _buildInlineVital('BP', pres['bp'].toString())),
                  if (pres['pulse'] != null)
                    Expanded(child: _buildInlineVital('Pulse', '${pres['pulse']} bpm')),
                  if (pres['temperature'] != null)
                    Expanded(child: _buildInlineVital('Temp', '${pres['temperature']} °F')),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Extra notes
            if (pres['medical_instructions'] != null && pres['medical_instructions'].toString().isNotEmpty) ...[
              _buildDetailSectionTitle('Doctor Instructions'),
              const SizedBox(height: 4),
              Text(
                pres['medical_instructions'].toString(),
                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w500, color: _Theme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: _Theme.textSecondary.withValues(alpha: 0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInlineVital(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: _Theme.textSecondary),
        ),
        Text(
          val,
          style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: _Theme.primary),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load History',
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: _Theme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Check your internet connection or availability and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: _Theme.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchHistory,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Try Again',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Theme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
