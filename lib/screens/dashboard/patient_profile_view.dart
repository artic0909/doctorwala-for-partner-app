import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'patient_medical_history.dart';
import 'create_prescription_form.dart';

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Profile Header Card
              FadeInDown(
                duration: const Duration(milliseconds: 350),
                child: _buildPatientHeaderCard(patient),
              ),
              const SizedBox(height: 20),

              // Summary Stats (Prescriptions & Reports)
              FadeInUp(
                duration: const Duration(milliseconds: 350),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Prescriptions',
                        count: noPrescriptions.toString(),
                        icon: Icons.description_rounded,
                        color: Colors.blueAccent,
                        onTap: _navigateToHistory,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Medical Reports',
                        count: noReports.toString(),
                        icon: Icons.science_rounded,
                        color: Colors.purpleAccent,
                        onTap: _navigateToHistory,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Highlighted "Create Prescription" Button
              FadeInUp(
                duration: const Duration(milliseconds: 380),
                child: ElevatedButton.icon(
                  onPressed: _navigateToCreatePrescription,
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'CREATE PRESCRIPTION',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Theme.accent,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: _Theme.accent.withValues(alpha: 0.2),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Vitals Section
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Latest Vitals', Icons.favorite_rounded, Colors.redAccent),
                    const SizedBox(height: 12),
                    _buildVitalsGrid(vitals),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bookings History Section
              FadeInUp(
                duration: const Duration(milliseconds: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Appointment History', Icons.history_rounded, _Theme.primary),
                    const SizedBox(height: 12),
                    if (bookings.isEmpty)
                      _buildEmptyBookingsState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index] as Map<String, dynamic>;
                          return _buildBookingCard(booking);
                        },
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _Theme.primary.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _Theme.accentLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Theme.accent.withValues(alpha: 0.15), width: 1.5),
                ),
                child: const Icon(Icons.person_rounded, color: _Theme.accent, size: 30),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _Theme.primary,
                            ),
                          ),
                        ),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _Theme.accent.withValues(alpha: 0.08),
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
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: _Theme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Medical ID: $cardNo',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          _buildContactInfoRow(Icons.email_outlined, 'Email Address', email),
          const SizedBox(height: 10),
          _buildContactInfoRow(Icons.phone_iphone_rounded, 'Mobile Number', phone),
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgAccent ? color.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgAccent ? color.withValues(alpha: 0.2) : _Theme.border,
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            displayValue,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _Theme.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 8,
              fontWeight: FontWeight.w800,
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
      child: Text(
        'No appointment history found for this patient.',
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _Theme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final date = booking['booking_date'] ?? 'N/A';
    final time = booking['booking_time'] ?? 'N/A';
    final clinicType = booking['clinic_type'] ?? 'N/A';
    final status = booking['status'] ?? 'Upcoming';

    final isPathology = clinicType.toLowerCase() == 'pathology';
    final serviceName = isPathology
        ? (booking['test']?['test_name'] ?? 'N/A')
        : (booking['doctor']?['doctor_name'] ?? 'N/A');

    Color statusColor;
    if (status == 'Completed') {
      statusColor = _Theme.accent;
    } else if (status == 'Cancelled') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orangeAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPathology ? Colors.purpleAccent : _Theme.accent).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  clinicType.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isPathology ? Colors.purple : _Theme.accent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isPathology ? 'Test Name: $serviceName' : 'Doctor: $serviceName',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _Theme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 12, color: _Theme.textSecondary),
              const SizedBox(width: 4),
              Text(
                date,
                style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Theme.textSecondary),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_rounded, size: 12, color: _Theme.textSecondary),
              const SizedBox(width: 4),
              Text(
                time,
                style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Theme.textSecondary),
              ),
            ],
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
