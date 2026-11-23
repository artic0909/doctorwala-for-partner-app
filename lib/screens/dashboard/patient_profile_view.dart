import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'patient_medical_history.dart';
import 'create_prescription_form.dart';
import 'create_handwritten_prescription_form.dart';
import '../../widgets/partner_skeleton_loader.dart';


class _Theme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Turquoise/Teal
  static const Color accentLight = Color(0xFFF0FDFA); // Soft Mint/Turquoise Light
  static const Color bgTint = Color(0xFFF8FAFC); // Slate background
  static const Color textSecondary = Color(0xFF64748B); // Medium slate
  static const Color border = Color(0xFFE2E8F0); // Border color
}

class PatientProfileViewScreen extends StatefulWidget {
  final String encryptedId;
  final Map<String, dynamic> partnerData;

  const PatientProfileViewScreen({
    super.key,
    required this.encryptedId,
    required this.partnerData,
  });

  @override
  State<PatientProfileViewScreen> createState() => _PatientProfileViewScreenState();
}

class _PatientProfileViewScreenState extends State<PatientProfileViewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
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

      final response = await ApiService.getPatientProfile(
        encryptedId: widget.encryptedId,
        token: token,
      );

      if (response['success'] == true) {
        setState(() {
          _profileData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to retrieve profile details.';
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

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientMedicalHistoryScreen(
          encryptedId: widget.encryptedId,
          partnerData: widget.partnerData,
        ),
      ),
    );
  }

  Future<void> _navigateToCreatePrescription() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: _Theme.accent),
      ),
    );

    try {
      final token = await SessionManager.getToken();
      if (!mounted) return;
      if (token == null) {
        Navigator.pop(context);
        CustomAlerts.showError(context, 'Authentication token missing.');
        return;
      }

      final response = await ApiService.getMedicalCardAccessMeta(token: token);
      if (!mounted) return;
      Navigator.pop(context);

      if (response['success'] == true) {
        final doctors = response['data']?['doctors'] as List? ?? [];
        final data = _profileData!;
        final patient = Map<String, dynamic>.from(data['patient'] ?? {});
        final vitals = Map<String, dynamic>.from(data['vital'] ?? {});

        if (!mounted) return;
        _showPrescriptionTypeBottomSheet(
          doctors: doctors,
          patient: patient,
          vitals: vitals,
        );
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? 'Failed to retrieve metadata.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      CustomAlerts.showError(context, 'An unexpected error occurred: ${e.toString()}');
    }
  }

  void _showPrescriptionTypeBottomSheet({
    required List<dynamic> doctors,
    required Map<String, dynamic> patient,
    required Map<String, dynamic> vitals,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Prescription',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _Theme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the prescription creation method below.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateHandwrittenPrescriptionScreen(
                                dwUserId: patient['id'] ?? 0,
                                patientData: patient,
                                doctors: doctors,
                                partnerData: widget.partnerData,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchProfile();
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _Theme.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: _Theme.accentLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: _Theme.accent,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hand Written',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _Theme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload scanned photo',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _Theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatePrescriptionScreen(
                                dwUserId: patient['id'] ?? 0,
                                patientData: patient,
                                doctors: doctors,
                                vitals: vitals,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchProfile();
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _Theme.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF), // soft blue
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: Color(0xFF3B82F6), // blue
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'System Digital',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _Theme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Generate prescription panel',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _Theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _Theme.bgTint,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const PartnerPatientProfileSkeleton(),
      );
    }

    if (_errorMessage != null || _profileData == null) {
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

    final data = _profileData!;
    final patient = data['patient'] ?? {};
    final vitals = data['vital'];
    final bookings = data['bookings'] as List? ?? [];
    final noPrescriptions = data['noOfPrescription'] ?? 0;
    final noReports = data['noOfReport'] ?? 0;

    return Scaffold(
      backgroundColor: _Theme.bgTint,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _Theme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Health Profile',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            color: _Theme.primary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_shared_rounded, color: _Theme.accent),
            tooltip: 'Medical History',
            onPressed: _navigateToHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: _Theme.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: (MediaQuery.paddingOf(context).bottom + 30).clamp(36.0, 60.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Profile Header Card
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: _buildPatientHeaderCard(patient),
              ),
              const SizedBox(height: 14),

              // Summary Stats (Prescriptions & Reports)
              FadeInUp(
                duration: const Duration(milliseconds: 320),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Prescriptions',
                        count: noPrescriptions.toString(),
                        icon: Icons.description_rounded,
                        color: const Color(0xFF0284C7),
                        onTap: _navigateToHistory,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Medical Reports',
                        count: noReports.toString(),
                        icon: Icons.science_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: _navigateToHistory,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Highlighted "Create Prescription" Button
              FadeInUp(
                duration: const Duration(milliseconds: 350),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToCreatePrescription,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                    label: Text(
                      'CREATE PRESCRIPTION',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Theme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Vitals Section
              FadeInUp(
                duration: const Duration(milliseconds: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Latest Vitals', Icons.favorite_rounded, Colors.redAccent),
                    const SizedBox(height: 10),
                    _buildVitalsGrid(vitals),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bookings History Section - Scrollable Appointments Carousel
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Appointment History', Icons.calendar_month_rounded, _Theme.primary),
                        if (bookings.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _Theme.accent.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${bookings.length} ${bookings.length == 1 ? 'Appointment' : 'Appointments'}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _Theme.accent,
                                  ),
                                ),
                                if (bookings.length > 1) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.swipe_rounded, size: 12, color: _Theme.accent),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (bookings.isEmpty)
                      _buildEmptyBookingsState()
                    else
                      SizedBox(
                        height: 154,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: bookings.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final booking = bookings[index] as Map<String, dynamic>;
                            return _buildBookingCard(booking, isHorizontal: true);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard(Map<String, dynamic> patient) {
    final name = patient['user_name'] ?? 'N/A';
    final cardNo = patient['medical_card_no'] ?? 'N/A';
    final email = patient['user_email'] ?? 'N/A';
    final phone = patient['user_mobile'] ?? 'N/A';
    final isVerified = patient['is_verified'] == true || patient['is_verified'] == 1 || patient['is_verified'] == '1';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withAlpha(22), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _Theme.accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Theme.accent.withAlpha(30), width: 1.0),
                ),
                child: const Icon(Icons.person_rounded, color: _Theme.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _Theme.primary,
                            ),
                          ),
                        ),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _Theme.accent.withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: _Theme.accent, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  'VERIFIED',
                                  style: GoogleFonts.manrope(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: _Theme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Medical ID: $cardNo',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _Theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          _buildContactInfoRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: 6),
          _buildContactInfoRow(Icons.phone_iphone_rounded, 'Mobile', phone),
        ],
      ),
    );
  }

  Widget _buildContactInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _Theme.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.manrope(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _Theme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _Theme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Theme.border, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _Theme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _Theme.textSecondary,
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
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _Theme.primary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsGrid(dynamic vitals) {
    final Map<String, dynamic> v = vitals is Map<String, dynamic> ? vitals : {};

    final bp = v['blood_pressure']?.toString() ?? 'N/A';
    final hr = v['heart_rate']?.toString() ?? 'N/A';
    final temp = v['temparature']?.toString() ?? 'N/A';
    final spo = v['spo']?.toString() ?? 'N/A';
    final sugar = v['blood_sugar']?.toString() ?? 'N/A';
    final weight = v['weight']?.toString() ?? 'N/A';
    final height = v['height']?.toString() ?? 'N/A';
    final bmi = v['bmi']?.toString() ?? 'N/A';
    final bloodGroup = v['blood_group']?.toString() ?? 'N/A';

    final vitalItems = [
      _buildVitalItem('Blood Pressure', bp, Icons.compress_rounded, Colors.redAccent, suffix: ' mmHg'),
      _buildVitalItem('Heart Rate', hr, Icons.favorite_rounded, Colors.redAccent, suffix: ' bpm'),
      _buildVitalItem('Temperature', temp, Icons.thermostat_rounded, Colors.orangeAccent, suffix: ' °F'),
      _buildVitalItem('SpO2', spo, Icons.bloodtype_rounded, Colors.blueAccent, suffix: ' %'),
      _buildVitalItem('Blood Sugar', sugar, Icons.biotech_rounded, Colors.purpleAccent, suffix: ' mg/dL'),
      _buildVitalItem('Weight', weight, Icons.scale_rounded, Colors.teal, suffix: ' kg'),
      _buildVitalItem('Height', height, Icons.height_rounded, Colors.indigoAccent, suffix: ' cm'),
      _buildVitalItem('BMI', bmi, Icons.calculate_rounded, Colors.blueGrey),
      _buildVitalItem('Blood Group', bloodGroup, Icons.water_drop_rounded, Colors.red, bgAccent: true),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vitalItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) => vitalItems[index],
    );
  }

  Widget _buildVitalItem(
    String title,
    String value,
    IconData icon,
    Color color, {
    String suffix = '',
    bool bgAccent = false,
  }) {
    final cleanValue = value == 'null' || value.isEmpty ? 'N/A' : value;
    final displayValue = cleanValue == 'N/A' ? 'N/A' : '$cleanValue$suffix';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgAccent ? color.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgAccent ? color.withAlpha(45) : _Theme.border,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            displayValue,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cleanValue == 'N/A' ? _Theme.textSecondary : _Theme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: _Theme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBookingsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Theme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 32, color: _Theme.textSecondary.withAlpha(100)),
          const SizedBox(height: 8),
          Text(
            'No appointment history found for this patient.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _Theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBookingDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'N/A' || str == 'null') return 'N/A';
    try {
      final parsed = DateTime.parse(str);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]}, ${parsed.year}';
    } catch (_) {
      return str;
    }
  }

  String _formatBookingTime(dynamic raw) {
    if (raw == null) return 'N/A';
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'N/A' || str == 'null') return 'N/A';
    try {
      final parts = str.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return '${hour.toString().padLeft(2, '0')}:$minute $period';
      }
    } catch (_) {}
    return str;
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {bool isHorizontal = false}) {
    final rawDate = booking['booking_date'] ?? booking['appointment_date'] ?? booking['date'];
    final rawTime = booking['booking_time'] ?? booking['appointment_time'] ?? booking['time'];
    final formattedDate = _formatBookingDate(rawDate);
    final formattedTime = _formatBookingTime(rawTime);

    final clinicType = (booking['clinic_type'] ?? booking['type'] ?? 'OPD').toString();
    final isPathology = clinicType.toLowerCase().contains('pathology') || clinicType.toLowerCase().contains('lab');

    // Extract doctor / test name with dynamic resolution
    final resService = booking['resolved_service_name']?.toString().trim();
    final resDoc = booking['resolved_doctor_name']?.toString().trim();

    String serviceName = 'N/A';
    if (resService != null && resService.isNotEmpty && resService != 'N/A') {
      serviceName = resService;
    } else if (resDoc != null && resDoc.isNotEmpty && resDoc != 'N/A') {
      serviceName = resDoc;
    } else if (isPathology) {
      if (booking['test'] is Map) {
        serviceName = booking['test']['test_name']?.toString() ??
            booking['test']['name']?.toString() ?? 'N/A';
      }
      if (serviceName == 'N/A') {
        serviceName = booking['test_name']?.toString() ??
            booking['clinic_test']?['test_name']?.toString() ??
            booking['service_name']?.toString() ?? 'Diagnostic Test';
      }
    } else {
      if (booking['doctor_contact'] is Map) {
        serviceName = booking['doctor_contact']['partner_doctor_name']?.toString() ?? 'N/A';
      }
      if (serviceName == 'N/A' && booking['doctor'] is Map) {
        serviceName = booking['doctor']['doctor_name']?.toString() ??
            booking['doctor']['name']?.toString() ?? 'N/A';
      }
      if (serviceName == 'N/A') {
        serviceName = booking['doctor_name']?.toString() ??
            booking['clinic_doctor']?['doctor_name']?.toString() ??
            booking['clinic_doctor']?['name']?.toString() ??
            booking['doctor_user']?['user_name']?.toString() ??
            booking['partner']?['clinic_name']?.toString() ??
            booking['clinic_name']?.toString() ?? 'Doctor Consultation';
      }
    }

    final status = (booking['status'] ?? 'Upcoming').toString();
    Color statusColor;
    Color statusBg;
    if (status.toLowerCase() == 'completed') {
      statusColor = _Theme.accent;
      statusBg = _Theme.accent.withAlpha(20);
    } else if (status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'rejected') {
      statusColor = Colors.redAccent;
      statusBg = Colors.redAccent.withAlpha(20);
    } else if (status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'accepted') {
      statusColor = Colors.teal;
      statusBg = Colors.teal.withAlpha(20);
    } else {
      statusColor = Colors.orange.shade700;
      statusBg = Colors.orange.shade50;
    }

    final cardWidth = isHorizontal ? 295.0 : double.infinity;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Theme.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPathology ? Colors.purple : _Theme.accent).withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPathology ? Icons.biotech_rounded : Icons.local_hospital_rounded,
                      size: 11,
                      color: isPathology ? Colors.purple : _Theme.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPathology ? 'PATHOLOGY' : 'OPD DOCTOR',
                      style: GoogleFonts.manrope(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isPathology ? Colors.purple : _Theme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isPathology ? Colors.purple : _Theme.primary).withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPathology ? Icons.science_outlined : Icons.person_outline_rounded,
                  size: 18,
                  color: isPathology ? Colors.purple : _Theme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _Theme.primary,
                      ),
                    ),
                    if (booking['serial_no'] != null || booking['booking_id'] != null)
                      Text(
                        booking['serial_no'] != null ? 'Token: #${booking['serial_no']}' : 'ID: #${booking['booking_id']}',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _Theme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Theme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: _Theme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: GoogleFonts.manrope(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _Theme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 11, color: _Theme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      formattedTime,
                      style: GoogleFonts.manrope(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _Theme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
              'Failed to Load Profile',
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
              onPressed: _fetchProfile,
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
