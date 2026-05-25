import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'create_prescription_form.dart';

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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final filteredHistories = histories.where((record) {
      final heading = (record['heading'] ?? '').toString().toLowerCase();
      final doctorName = (record['doctor_name'] ?? record['doctor']?['doctor_name'] ?? '').toString().toLowerCase();
      final clinicName = (record['clinic_name'] ?? record['opd']?['partner_clinic_name'] ?? '').toString().toLowerCase();
      final type = (record['type'] ?? '').toString().toLowerCase();

      final matchesSearch = heading.contains(_searchQuery.toLowerCase()) ||
          doctorName.contains(_searchQuery.toLowerCase()) ||
          clinicName.contains(_searchQuery.toLowerCase()) ||
          type.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedDateRange != null) {
        final dateStr = record['date_of_report'] != null
            ? record['date_of_report'].toString().split('T')[0]
            : null;
        if (dateStr == null) return false;
        try {
          final date = DateTime.parse(dateStr);
          final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
          if (date.isBefore(start) || date.isAfter(end)) return false;
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();

    final filteredSystemPrescriptions = systemPrescriptions.where((pres) {
      final doctorName = (pres['doctor_name'] ?? pres['doctor']?['doctor_name'] ?? '').toString().toLowerCase();
      final clinicName = (pres['opd']?['partner_clinic_name'] ?? '').toString().toLowerCase();
      final heading = (pres['heading'] ?? '').toString().toLowerCase();

      final matchesSearch = doctorName.contains(_searchQuery.toLowerCase()) ||
          clinicName.contains(_searchQuery.toLowerCase()) ||
          heading.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedDateRange != null) {
        final dateStr = pres['prescription_date'] != null
            ? pres['prescription_date'].toString().split('T')[0]
            : null;
        if (dateStr == null) return false;
        try {
          final date = DateTime.parse(dateStr);
          final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
          if (date.isBefore(start) || date.isAfter(end)) return false;
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();

    final bool isFiltered = _searchQuery.isNotEmpty || _selectedDateRange != null;

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
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Tab 1: Uploaded Medical Files
                  RefreshIndicator(
                    onRefresh: _fetchHistory,
                    color: _Theme.accent,
                    child: filteredHistories.isEmpty
                        ? _buildEmptyState(
                            isFiltered ? 'No Matches Found' : 'No Uploaded Files',
                            isFiltered
                                ? 'No external reports match your active search queries or date filters.'
                                : 'There are no external reports or prescription files uploaded for this patient.',
                            isFilterEmpty: isFiltered,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                            itemCount: filteredHistories.length,
                            itemBuilder: (context, index) {
                              final record = filteredHistories[index] as Map<String, dynamic>;
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
                    child: filteredSystemPrescriptions.isEmpty
                        ? _buildEmptyState(
                            isFiltered ? 'No Matches Found' : 'No Prescriptions',
                            isFiltered
                                ? 'No system-generated digital prescriptions match your active search queries or date filters.'
                                : 'There are no system-generated digital prescriptions found in history.',
                            isFilterEmpty: isFiltered,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                            itemCount: filteredSystemPrescriptions.length,
                            itemBuilder: (context, index) {
                              final pres = filteredSystemPrescriptions[index] as Map<String, dynamic>;
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreatePrescription,
          backgroundColor: _Theme.accent,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by heading, doctor or clinic...',
              hintStyle: GoogleFonts.manrope(
                fontSize: 13,
                color: _Theme.textSecondary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: _Theme.accent, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(Icons.clear_rounded, color: _Theme.textSecondary, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: _Theme.bgTint,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _Theme.accent, width: 1.2),
              ),
            ),
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              color: _Theme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedDateRange == null ? _Theme.bgTint : _Theme.accentLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedDateRange == null ? _Theme.border : _Theme.accent.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 15,
                          color: _selectedDateRange == null ? _Theme.textSecondary : _Theme.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDateRange == null
                                ? 'Filter by Date Range'
                                : '${_selectedDateRange!.start.toString().split(' ')[0]}  to  ${_selectedDateRange!.end.toString().split(' ')[0]}',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _selectedDateRange == null ? _Theme.textSecondary : _Theme.accent,
                            ),
                          ),
                        ),
                        if (_selectedDateRange != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDateRange = null;
                              });
                            },
                            child: const Icon(
                              Icons.cancel_rounded,
                              size: 15,
                              color: _Theme.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _Theme.accent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _Theme.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _Theme.accent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
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

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePrescriptionScreen(
              dwUserId: _historyData!['patient']?['id'] ?? 0,
              patientData: Map<String, dynamic>.from(_historyData!['patient'] ?? {}),
              doctors: doctors,
              vitals: Map<String, dynamic>.from(_historyData!['vital'] ?? {}),
            ),
          ),
        );

        if (result == true) {
          _fetchHistory();
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

  Widget _buildEmptyState(String title, String desc, {bool isFilterEmpty = false}) {
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

  void _openWebPage(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        CustomAlerts.showError(context, 'Could not open prescription link.');
      }
    }
  }

  Widget _buildSystemPrescriptionCard(Map<String, dynamic> pres) {
    final date = pres['prescription_date'] != null
        ? pres['prescription_date'].toString().split('T')[0]
        : 'N/A';
    final doctorName = pres['doctor_name'] ?? pres['doctor']?['doctor_name'] ?? 'N/A';
    final clinicName = pres['opd']?['partner_clinic_name'] ?? 'N/A';
    final heading = pres['heading'] ?? 'General Checkup';

    final symptomsRaw = pres['symptoms'];
    final testsRaw = pres['recommended_tests'];
    final medicinesRaw = pres['medicines'];

    List<String> symptoms = [];
    if (symptomsRaw is List) {
      symptoms = symptomsRaw.map((e) => e.toString()).toList();
    } else if (symptomsRaw is String) {
      symptoms = [symptomsRaw];
    }

    List<dynamic> tests = [];
    if (testsRaw is List) {
      tests = testsRaw;
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
                heading,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _Theme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prescribed by Dr. $doctorName',
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _Theme.textSecondary,
                ),
              ),
              Text(
                'Clinic: $clinicName',
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _Theme.textSecondary,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // View PDF Button
            ElevatedButton.icon(
              onPressed: () {
                final encryptedId = pres['encrypted_id'] ?? pres['id'].toString();
                final url = 'https://www.doctorwala.info/share/prescription/$encryptedId/view';
                _openWebPage(url);
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: Text(
                'View Prescription PDF',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Theme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Vitals Grid (Uniform Presentation)
            _buildVitalsGrid(pres),
            const SizedBox(height: 14),

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
                  side: const BorderSide(color: _Theme.border),
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
                  final mName = med['name'] ?? 'N/A';
                  
                  final timingRaw = med['timing'];
                  String mTiming = 'N/A';
                  if (timingRaw is List) {
                    mTiming = timingRaw.join(', ');
                  } else if (timingRaw is String) {
                    mTiming = timingRaw;
                  }

                  final eatingRaw = med['eating'];
                  String mEating = '';
                  if (eatingRaw is List) {
                    mEating = eatingRaw.join(', ');
                  } else if (eatingRaw is String) {
                    mEating = eatingRaw;
                  }

                  final mDuration = med['days'] ?? med['duration'] ?? 'N/A';

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
                                  text: '\nFrequency: $mTiming'
                                      '${mEating.isNotEmpty ? ' | Relation: $mEating' : ''}'
                                      ' | Duration: $mDuration Days',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: _Theme.textSecondary,
                                    height: 1.4,
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
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tests.length,
                itemBuilder: (context, idx) {
                  final test = tests[idx];
                  if (test is Map) {
                    final tName = test['name'] ?? 'N/A';
                    final tPriority = test['priority'] ?? 'Normal';
                    final tNotes = test['notes'] ?? '';
                    
                    Color priorityColor = Colors.grey;
                    if (tPriority == 'Urgent') priorityColor = Colors.orangeAccent.shade700;
                    if (tPriority == 'Critical') priorityColor = Colors.redAccent;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                              Expanded(
                                child: Text(
                                  tName,
                                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: _Theme.primary),
                                ),
                              ),
                              if (tPriority != 'Normal')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tPriority.toUpperCase(),
                                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: priorityColor),
                                  ),
                                ),
                            ],
                          ),
                          if (tNotes.toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 10, top: 2),
                              child: Text(
                                'Note: $tNotes',
                                style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Theme.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('• ${test.toString()}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _Theme.primary)),
                  );
                },
              ),
              const SizedBox(height: 14),
            ],

            // Advice / Diet instructions
            if ((pres['medical_instructions'] != null && pres['medical_instructions'].toString().isNotEmpty) ||
                (pres['diet_instructions'] != null && pres['diet_instructions'].toString().isNotEmpty)) ...[
              _buildDetailSectionTitle('Advice & Instructions'),
              const SizedBox(height: 8),
              if (pres['medical_instructions'] != null && pres['medical_instructions'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    'Medical: ${pres['medical_instructions']}',
                    style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: _Theme.textSecondary),
                  ),
                ),
              if (pres['diet_instructions'] != null && pres['diet_instructions'].toString().isNotEmpty)
                Text(
                  'Diet: ${pres['diet_instructions']}',
                  style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: _Theme.textSecondary),
                ),
              const SizedBox(height: 14),
            ],

            // Follow-up
            if (pres['next_visit_date'] != null || pres['repeat_tests_required'] == true || (pres['emergency_note'] != null && pres['emergency_note'].toString().isNotEmpty)) ...[
              _buildDetailSectionTitle('Follow Up'),
              const SizedBox(height: 8),
              if (pres['next_visit_date'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Next Visit: ${pres['next_visit_date'].toString().split(' ')[0]}',
                    style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: _Theme.primary),
                  ),
                ),
              if (pres['repeat_tests_required'] == true)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Repeat Tests Required: Yes',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ),
              if (pres['emergency_note'] != null && pres['emergency_note'].toString().isNotEmpty)
                Text(
                  'Emergency Note: ${pres['emergency_note']}',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsGrid(Map<String, dynamic> pres) {
    final List<Widget> vitalWidgets = [];

    void addVital(String label, String? value, IconData icon) {
      if (value != null && value.toString().isNotEmpty) {
        vitalWidgets.add(
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _Theme.bgTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Theme.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: _Theme.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: _Theme.textSecondary)),
                      Text(value, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w800, color: _Theme.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    addVital('Age', pres['user_age'], Icons.calendar_today_rounded);
    addVital('Gender', pres['user_gender'], Icons.face_rounded);
    addVital('Blood', pres['blood_group'], Icons.water_drop_rounded);
    addVital('BP', pres['bp'], Icons.monitor_heart_rounded);
    addVital('Pulse', pres['pulse'] != null && pres['pulse'].toString().isNotEmpty ? '${pres['pulse']} bpm' : null, Icons.heart_broken_rounded);
    addVital('SpO2', pres['spo2'] != null && pres['spo2'].toString().isNotEmpty ? '${pres['spo2']}%' : null, Icons.air_rounded);
    addVital('Temp', pres['temperature'] != null && pres['temperature'].toString().isNotEmpty ? '${pres['temperature']} °F' : null, Icons.thermostat_rounded);
    addVital('Weight', pres['weight'] != null && pres['weight'].toString().isNotEmpty ? '${pres['weight']} kg' : null, Icons.scale_rounded);

    if (vitalWidgets.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: vitalWidgets,
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
